"""Generate a Harbor claims landscape that uses every ArchiMate element type.

The model is one enterprise, drawn as three views:

- Context diagram: who is outside the enterprise, the product, and the location
- Conceptual architecture: motivation and strategy
- Logical architecture: business, application, technology, physical, and change

Grouping boxes hold the elements on each view. pyArchimate nests a child with
``node.add(..., nested_rel_type="Aggregation")``, which writes the child inside
the group and adds an aggregation from the grouping to that element.

Inside each group the elements sit on a grid: one column per vertical story,
with a gap between columns and an empty band between rows. A relationship
whose ends share a row or a column is left straight. A relationship that
would pass through another element is drawn through an empty band with
bendpoints. A link between two groups stays in one column, through the gap
between the boxes. Junctions are 20px circles centred on their cell, because
a junction drawn at element size becomes a wide oval.

Run from this pyarchimate folder. On Windows with Git Bash, follow README.md
(pyenv-win for the Python version, then a venv). On macOS or Linux:

    python3 -m venv .venv
    .venv/bin/pip install -r requirements.txt
    .venv/bin/python examples/generate_harbor_landscape.py

Then in Archi: File > Open, and choose

    examples/out/harbor-landscape.archimate

The same model is also written as Open Group exchange XML. In Archi that file
is File > Import > Open Exchange Format:

    examples/out/harbor-landscape.xml

pyArchimate checks each relationship against the ArchiMate matrix. All three
views use Archi's ``layered`` viewpoint, which allows every concept. Viewpoint
ids are stamped onto the Archi file after export.
"""

from __future__ import annotations

import zipfile
from pathlib import Path

from lxml import etree
from pyArchimate import ArchiType, Model
from pyArchimate.relationship import check_valid_relationship
from pyArchimate.view import Point

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "examples" / "out"

XSI_TYPE = "{http://www.w3.org/2001/XMLSchema-instance}type"

ARCHI_VIEWPOINTS = {
    "Context diagram": "layered",
    "Conceptual architecture": "layered",
    "Logical architecture": "layered",
}

RELATIONSHIP_TYPES = {
    "Association",
    "Assignment",
    "Realization",
    "Serving",
    "Composition",
    "Aggregation",
    "Access",
    "Influence",
    "Triggering",
    "Flow",
    "Specialization",
}

ELEMENT_TYPES = {
    member.value
    for member in ArchiType
    if member.value not in RELATIONSHIP_TYPES and member is not ArchiType.View
}

BUSINESS = "/Business/Harbor"
APPLICATION = "/Application/Harbor"
TECHNOLOGY = "/Technology/Harbor"
PHYSICAL = "/Physical/Harbor"
MOTIVATION = "/Motivation/Harbor"
STRATEGY = "/Strategy/Harbor"
CHANGE = "/Implementation & Migration/Harbor"
OTHER = "/Other/Harbor"
VIEWS = "/Views/Harbor"


def relate(model: Model, rel_type: str, source, target, name: str = ""):
    """Add a relationship and refuse a pair the ArchiMate matrix rejects."""
    check_valid_relationship(rel_type, source.type, target.type, raise_flg=True)
    return model.add_relationship(rel_type, source=source, target=target, name=name)


# Same column pitch as the claims example. 210px columns leave a 62px gap
# beside a 148px element. 200px rows leave a clear band between the rows.
# Junctions stay 20px circles, centred in the cell, so a line along the row
# or the column still meets the circle at its middle.
W = 148
H = 58
COL = 210
ROW = 200
JUNCTION = 20
PAD_X = 32
PAD_TOP = 56
PAD_BOTTOM = 48
GROUP_GAP = 80
SHIFT = 18
JUNCTION_TYPES = {ArchiType.Junction, ArchiType.OrJunction, ArchiType.AndJunction}


def place_group(view, grouping, positions, x: int, y: int, pad_bottom: int = PAD_BOTTOM):
    """Nest each element at its own column and row inside the grouping box.

    ``positions`` maps an element to ``(column, row)``. Columns line up across
    groups when every group starts at the same x. ``pad_bottom`` grows when a
    lane has to travel under the last row.
    """
    columns = max(col for col, _row in positions.values()) + 1
    rows = max(row for _col, row in positions.values()) + 1
    width = PAD_X * 2 + (columns - 1) * COL + W
    height = PAD_TOP + (rows - 1) * ROW + H + pad_bottom
    box = view.add(grouping, x=x, y=y, w=width, h=height)
    nodes = {grouping: box}
    for element, (col, row) in positions.items():
        check_valid_relationship("Aggregation", grouping.type, element.type, raise_flg=True)
        w, h = (JUNCTION, JUNCTION) if element.type in JUNCTION_TYPES else (W, H)
        nodes[element] = box.add(
            element,
            x=x + PAD_X + col * COL + (W - w) / 2,
            y=y + PAD_TOP + row * ROW + (H - h) / 2,
            w=w,
            h=h,
            nested_rel_type="Aggregation",
        )
    return nodes, height


def draw(view, relationships, nodes):
    """Draw every relationship whose two ends are both on this view."""
    drawn = {}
    for relationship in relationships:
        if relationship.source in nodes and relationship.target in nodes:
            drawn[relationship] = view.add_connection(relationship)
    return drawn


def between(drawn, source, target):
    """Return the connection already drawn from source to target."""
    for relationship, connection in drawn.items():
        if relationship.source is source and relationship.target is target:
            return connection
    raise KeyError(f"No connection from {source.name} to {target.name}")


def lane(connection, y: float, source_x: float | None = None, target_x: float | None = None):
    """Route a connection across an empty horizontal band."""
    connection.add_bendpoint(
        Point(connection.source.cx if source_x is None else source_x, y),
        Point(connection.target.cx if target_x is None else target_x, y),
    )


def band(node, slot: int = 0) -> float:
    """Y of an empty lane just below this element. Slots keep parallel lines apart."""
    return node.y + node.h + 16 + slot * 22


def _contains(node, x: float, y: float) -> bool:
    return node.x <= x <= node.x + node.w and node.y <= y <= node.y + node.h


def _segment_hits_rect(x1, y1, x2, y2, left, top, right, bottom) -> bool:
    """True when the open segment passes through the rectangle."""
    dx = x2 - x1
    dy = y2 - y1
    p = (-dx, dx, -dy, dy)
    q = (x1 - left, right - x1, y1 - top, bottom - y1)
    u1, u2 = 0.0, 1.0
    for pi, qi in zip(p, q):
        if pi == 0:
            if qi < 0:
                return False
            continue
        t = qi / pi
        if pi < 0:
            if t > u2:
                return False
            u1 = max(u1, t)
        else:
            if t < u1:
                return False
            u2 = min(u2, t)
    return u1 < u2 and u2 > 0.02 and u1 < 0.98


def check_routes(view) -> None:
    """Fail when a drawn line passes through an element that is not an end.

    A segment that starts or ends inside a grouping box is leaving or entering
    that box. The box itself is not a crossing. Sibling elements still are.
    """
    nodes = []

    def walk(items):
        for node in items:
            nodes.append(node)
            walk(node.nodes)

    walk(view.nodes)
    missing = []
    for connection in view.conns:
        points = [(connection.source.cx, connection.source.cy)]
        points.extend((point.x, point.y) for point in connection.bendpoints)
        points.append((connection.target.cx, connection.target.cy))
        for (x1, y1), (x2, y2) in zip(points, points[1:]):
            for node in nodes:
                if node is connection.source or node is connection.target:
                    continue
                if _contains(node, x1, y1) or _contains(node, x2, y2):
                    continue
                if _segment_hits_rect(
                    x1, y1, x2, y2, node.x + 2, node.y + 2, node.x + node.w - 2, node.y + node.h - 2
                ):
                    missing.append(
                        f"{view.name}: line {connection.source.name} -> {connection.target.name} crosses {node.name}"
                    )
    if missing:
        raise SystemExit("\n".join(dict.fromkeys(missing)))


def count_nodes(view) -> int:
    """Count the grouping boxes and the elements nested inside them."""

    def walk(nodes) -> int:
        total = 0
        for node in nodes:
            total += 1 + walk(node.nodes)
        return total

    return walk(view.nodes)


def build() -> Model:
    model = Model("Harbor claims landscape")
    model.desc = (
        "Generated by examples/generate_harbor_landscape.py. "
        "A Harbor insurer settles motor claims. The context diagram shows who "
        "meets the enterprise, the conceptual view shows why and which "
        "capabilities matter, and the logical view shows how the business, "
        "applications, platform, premises, and change fit together. "
        "Every ArchiMate 3 element type appears at least once."
    )

    # Context: the enterprise boundary and the people who meet it.
    customer = model.add(
        ArchiType.BusinessActor,
        "Customer",
        desc="Person who holds the policy and reports the loss.",
        folder=BUSINESS,
    )
    policyholder = model.add(ArchiType.BusinessRole, "Policyholder", folder=BUSINESS)
    claimant = model.add(ArchiType.BusinessRole, "Claimant", folder=BUSINESS)
    claims_desk = model.add(ArchiType.BusinessInterface, "Claims desk", folder=BUSINESS)
    product = model.add(ArchiType.Product, "Motor cover", folder=BUSINESS)
    contract = model.add(ArchiType.Contract, "Policy wording", folder=BUSINESS)
    claim_notice = model.add(ArchiType.Representation, "Claim notice", folder=BUSINESS)
    office = model.add(ArchiType.Location, "Harbor office", folder=OTHER)

    # Conceptual: motivation.
    director = model.add(ArchiType.Stakeholder, "Claims director", folder=MOTIVATION)
    speed = model.add(ArchiType.Driver, "Settlement speed", folder=MOTIVATION)
    cycle_gap = model.add(ArchiType.Assessment, "Cycle time gap", folder=MOTIVATION)
    five_days = model.add(ArchiType.Goal, "Settle in five days", folder=MOTIVATION)
    faster = model.add(ArchiType.Outcome, "Faster settlement", folder=MOTIVATION)
    straight_through = model.add(ArchiType.Principle, "Straight-through handling", folder=MOTIVATION)
    record_claim = model.add(ArchiType.Requirement, "Record every claim", folder=MOTIVATION)
    retain = model.add(ArchiType.Constraint, "Retain claim data", folder=MOTIVATION)
    meaning = model.add(ArchiType.Meaning, "A claim is a request to pay", folder=MOTIVATION)
    trust = model.add(ArchiType.Value, "Trust", folder=MOTIVATION)

    # Conceptual: strategy.
    staff = model.add(ArchiType.Resource, "Claims staff", folder=STRATEGY)
    settlement = model.add(ArchiType.Capability, "Claims settlement", folder=STRATEGY)
    digitize = model.add(ArchiType.CourseOfAction, "Digitize intake", folder=STRATEGY)
    claim_to_payment = model.add(ArchiType.ValueStream, "Claim to payment", folder=STRATEGY)

    # Logical: business behavior.
    board = model.add(ArchiType.BusinessCollaboration, "Claims board", folder=BUSINESS)
    register = model.add(ArchiType.BusinessProcess, "Register claim", folder=BUSINESS)
    handling = model.add(ArchiType.BusinessFunction, "Case handling", folder=BUSINESS)
    meeting = model.add(ArchiType.BusinessInteraction, "Settlement meeting", folder=BUSINESS)
    submitted = model.add(ArchiType.BusinessEvent, "Claim submitted", folder=BUSINESS)
    claims_service = model.add(ArchiType.BusinessService, "Claims handling", folder=BUSINESS)
    claim_file = model.add(ArchiType.BusinessObject, "Claim file", folder=BUSINESS)
    channel_choice = model.add(ArchiType.OrJunction, "Channel choice", folder=OTHER)
    intake_split = model.add(ArchiType.Junction, "Intake split", folder=OTHER)

    # Logical: applications.
    claims_system = model.add(ArchiType.ApplicationComponent, "Claims system", folder=APPLICATION)
    document_store = model.add(ArchiType.ApplicationComponent, "Document store", folder=APPLICATION)
    claims_api = model.add(ArchiType.ApplicationInterface, "Claims API", folder=APPLICATION)
    dialogue = model.add(ArchiType.ApplicationInteraction, "Adjudication dialogue", folder=APPLICATION)
    suite = model.add(ArchiType.ApplicationCollaboration, "Claims application suite", folder=APPLICATION)
    validate = model.add(ArchiType.ApplicationFunction, "Validate coverage", folder=APPLICATION)
    register_case = model.add(ArchiType.ApplicationProcess, "Register claim case", folder=APPLICATION)
    received = model.add(ArchiType.ApplicationEvent, "Claim received", folder=APPLICATION)
    app_service = model.add(ArchiType.ApplicationService, "Claims application service", folder=APPLICATION)
    claim_record = model.add(ArchiType.DataObject, "Claim record", folder=APPLICATION)
    intake_join = model.add(ArchiType.AndJunction, "Intake join", folder=OTHER)

    # Logical: technology and physical.
    host = model.add(ArchiType.Node, "Claims host", folder=TECHNOLOGY)
    server = model.add(ArchiType.Device, "App server", folder=TECHNOLOGY)
    link = model.add(ArchiType.Path, "Data center link", folder=TECHNOLOGY)
    network = model.add(ArchiType.CommunicationNetwork, "Harbor network", folder=TECHNOLOGY)
    runtime = model.add(ArchiType.SystemSoftware, "Claims runtime", folder=TECHNOLOGY)
    cluster = model.add(ArchiType.TechnologyCollaboration, "Platform cluster", folder=TECHNOLOGY)
    host_api = model.add(ArchiType.TechnologyInterface, "Host API", folder=TECHNOLOGY)
    workload = model.add(ArchiType.TechnologyFunction, "Run workload", folder=TECHNOLOGY)
    deploy = model.add(ArchiType.TechnologyProcess, "Deploy release", folder=TECHNOLOGY)
    handshake = model.add(ArchiType.TechnologyInteraction, "Cluster handshake", folder=TECHNOLOGY)
    node_started = model.add(ArchiType.TechnologyEvent, "Node started", folder=TECHNOLOGY)
    compute = model.add(ArchiType.TechnologyService, "Compute service", folder=TECHNOLOGY)
    package = model.add(ArchiType.Artifact, "Claims package", folder=TECHNOLOGY)
    rack = model.add(ArchiType.Equipment, "Rack", folder=PHYSICAL)
    hall = model.add(ArchiType.Facility, "Harbor data hall", folder=PHYSICAL)
    power = model.add(ArchiType.DistributionNetwork, "Power feed", folder=PHYSICAL)
    disk = model.add(ArchiType.Material, "Spare disk", folder=PHYSICAL)

    # Logical: implementation and migration.
    intake_work = model.add(ArchiType.WorkPackage, "Intake digitization", folder=CHANGE)
    digital_intake = model.add(ArchiType.Deliverable, "Digital intake", folder=CHANGE)
    go_live = model.add(ArchiType.ImplementationEvent, "Go live", folder=CHANGE)
    live = model.add(ArchiType.Plateau, "Digital intake live", folder=CHANGE)
    manual_gap = model.add(ArchiType.Gap, "Manual intake gap", folder=CHANGE)

    # Groupings. Each box is a real Grouping element, not only a visual frame.
    enterprise = model.add(ArchiType.Grouping, "Harbor claims enterprise", folder=OTHER)
    motivation_group = model.add(ArchiType.Grouping, "Motivation", folder=OTHER)
    strategy_group = model.add(ArchiType.Grouping, "Strategy", folder=OTHER)
    business_group = model.add(ArchiType.Grouping, "Business landscape", folder=OTHER)
    application_group = model.add(ArchiType.Grouping, "Application landscape", folder=OTHER)
    platform_group = model.add(ArchiType.Grouping, "Technology and physical landscape", folder=OTHER)
    change_group = model.add(ArchiType.Grouping, "Change roadmap", folder=OTHER)

    relationships = [
        relate(model, "Assignment", customer, policyholder, "plays"),
        relate(model, "Specialization", claimant, policyholder, "is a"),
        relate(model, "Association", customer, office),
        relate(model, "Composition", product, contract),
        relate(model, "Association", trust, product),
        relate(model, "Serving", claims_desk, claims_service),
        relate(model, "Association", claim_notice, claim_file),
        relate(model, "Association", contract, claim_file),
        relate(model, "Association", director, speed),
        relate(model, "Association", director, five_days),
        relate(model, "Association", director, cycle_gap),
        relate(model, "Influence", speed, five_days),
        relate(model, "Influence", speed, cycle_gap),
        relate(model, "Influence", speed, faster),
        relate(model, "Influence", cycle_gap, five_days),
        relate(model, "Influence", cycle_gap, faster),
        relate(model, "Realization", faster, five_days),
        relate(model, "Realization", straight_through, five_days),
        relate(model, "Influence", straight_through, record_claim),
        relate(model, "Influence", retain, record_claim),
        relate(model, "Influence", five_days, record_claim),
        relate(model, "Association", meaning, trust),
        relate(model, "Association", meaning, claim_file),
        relate(model, "Assignment", staff, settlement),
        relate(model, "Serving", staff, digitize),
        relate(model, "Serving", digitize, settlement),
        relate(model, "Realization", settlement, five_days),
        relate(model, "Serving", settlement, claim_to_payment),
        relate(model, "Assignment", policyholder, register),
        relate(model, "Serving", board, register),
        relate(model, "Composition", handling, register),
        relate(model, "Triggering", meeting, register),
        relate(model, "Triggering", submitted, channel_choice),
        relate(model, "Triggering", channel_choice, register),
        relate(model, "Triggering", register, intake_split),
        relate(model, "Flow", intake_split, handling),
        relate(model, "Flow", register, handling),
        relate(model, "Realization", register, claims_service),
        relate(model, "Serving", claims_service, register),
        relate(model, "Access", register, claim_file),
        relate(model, "Aggregation", suite, claims_system),
        relate(model, "Aggregation", suite, document_store),
        relate(model, "Composition", claims_system, claims_api),
        relate(model, "Realization", claims_system, app_service),
        relate(model, "Access", claims_system, claim_record),
        relate(model, "Flow", claims_system, document_store, "stores the notice"),
        relate(model, "Serving", claims_api, app_service),
        relate(model, "Access", validate, claim_record),
        relate(model, "Triggering", register_case, validate),
        relate(model, "Realization", register_case, app_service),
        relate(model, "Flow", received, intake_join),
        relate(model, "Flow", intake_join, register_case),
        relate(model, "Triggering", received, register_case),
        relate(model, "Flow", dialogue, register_case),
        relate(model, "Serving", app_service, register),
        relate(model, "Composition", host, server),
        relate(model, "Composition", host, runtime),
        relate(model, "Realization", host, compute),
        relate(model, "Aggregation", cluster, host),
        relate(model, "Association", server, link),
        relate(model, "Association", link, network),
        relate(model, "Realization", package, runtime),
        relate(model, "Serving", host_api, compute),
        relate(model, "Serving", workload, compute),
        relate(model, "Realization", deploy, compute),
        relate(model, "Flow", deploy, workload),
        relate(model, "Access", deploy, package),
        relate(model, "Flow", handshake, workload),
        relate(model, "Triggering", node_started, deploy),
        relate(model, "Serving", compute, host),
        relate(model, "Realization", rack, compute),
        relate(model, "Composition", hall, rack),
        relate(model, "Association", hall, office),
        relate(model, "Association", power, disk),
        relate(model, "Realization", intake_work, digital_intake),
        relate(model, "Triggering", intake_work, go_live),
        relate(model, "Triggering", go_live, intake_work),
        relate(model, "Triggering", live, intake_work),
        relate(model, "Realization", digital_intake, live),
        relate(model, "Realization", live, five_days),
        relate(model, "Association", manual_gap, live),
        relate(model, "Association", manual_gap, five_days),
    ]

    context = model.add(
        ArchiType.View,
        "Context diagram",
        desc="Customers, the motor product, and the Harbor office around the enterprise.",
        folder=VIEWS,
    )
    # Office sits under the customer, and the contract sits beside the product,
    # so each drawn link is one step on the grid.
    context_nodes, _ = place_group(
        context,
        enterprise,
        {
            customer: (0, 0),
            policyholder: (1, 0),
            claimant: (2, 0),
            claims_desk: (3, 0),
            office: (0, 1),
            product: (1, 1),
            contract: (2, 1),
            claim_notice: (3, 1),
        },
        x=40,
        y=40,
    )
    draw(context, relationships, context_nodes)
    check_routes(context)

    conceptual = model.add(
        ArchiType.View,
        "Conceptual architecture",
        desc="Why the enterprise settles claims faster, and the capability it invests in.",
        folder=VIEWS,
    )
    # Column 0 is the goal, with the settlement capability directly under it.
    # The requirement chain sits on the goal's row. Column 0 of that row's
    # neighbour is empty, so the influences can drop beside the director.
    motivation_nodes, motivation_height = place_group(
        conceptual,
        motivation_group,
        {
            director: (0, 0),
            speed: (1, 0),
            cycle_gap: (2, 0),
            faster: (3, 0),
            five_days: (0, 1),
            straight_through: (1, 1),
            record_claim: (2, 1),
            retain: (3, 1),
            meaning: (4, 1),
            trust: (5, 1),
        },
        x=40,
        y=40,
        pad_bottom=80,
    )
    strategy_nodes, _strategy_height = place_group(
        conceptual,
        strategy_group,
        {
            settlement: (0, 0),
            staff: (1, 0),
            claim_to_payment: (2, 0),
            digitize: (1, 1),
        },
        x=40,
        y=40 + motivation_height + GROUP_GAP,
    )
    conceptual_nodes = {**motivation_nodes, **strategy_nodes}
    conceptual_lines = draw(conceptual, relationships, conceptual_nodes)
    goal = motivation_nodes[five_days]
    driver = motivation_nodes[speed]
    # Influences from the top row join one drop just left of the goal.
    lane(between(conceptual_lines, director, cycle_gap), band(motivation_nodes[director], 0))
    lane(between(conceptual_lines, speed, faster), band(driver, 1))
    for source, slot in ((speed, 2), (cycle_gap, 3), (faster, 4)):
        lane(
            between(conceptual_lines, source, five_days),
            band(driver, slot),
            target_x=goal.cx - SHIFT,
        )
    # Record every claim is two columns away, so the line goes under the row.
    lane(
        between(conceptual_lines, five_days, record_claim),
        band(goal, 0),
        source_x=goal.cx + SHIFT,
        target_x=motivation_nodes[record_claim].cx + SHIFT,
    )
    lane(between(conceptual_lines, settlement, claim_to_payment), band(strategy_nodes[settlement], 0))
    lane(between(conceptual_lines, digitize, settlement), band(strategy_nodes[settlement], 1))
    check_routes(conceptual)

    logical = model.add(
        ArchiType.View,
        "Logical architecture",
        desc=(
            "Business behavior, the applications that support it, the platform and "
            "premises underneath, and the change that digitizes intake."
        ),
        folder=VIEWS,
    )
    cursor_y = 40
    # Register claim is on the bottom row with an empty cell above it, in the
    # same column as Claims application service in the group below.
    business_nodes, business_height = place_group(
        logical,
        business_group,
        {
            submitted: (0, 0),
            channel_choice: (1, 0),
            intake_split: (3, 0),
            handling: (4, 0),
            meeting: (5, 0),
            board: (0, 1),
            claims_service: (1, 1),
            register: (2, 1),
            claim_file: (4, 1),
        },
        x=40,
        y=cursor_y,
        pad_bottom=100,
    )
    cursor_y += business_height + GROUP_GAP
    application_nodes, application_height = place_group(
        logical,
        application_group,
        {
            suite: (0, 0),
            app_service: (2, 0),
            claims_system: (3, 0),
            claims_api: (4, 0),
            document_store: (0, 1),
            claim_record: (3, 1),
            validate: (4, 1),
            register_case: (5, 1),
            intake_join: (2, 2),
            received: (3, 2),
            dialogue: (5, 2),
        },
        x=40,
        y=cursor_y,
    )
    cursor_y += application_height + GROUP_GAP
    platform_nodes, platform_height = place_group(
        logical,
        platform_group,
        {
            cluster: (0, 0),
            host: (1, 0),
            server: (2, 0),
            link: (3, 0),
            network: (4, 0),
            package: (0, 1),
            runtime: (1, 1),
            compute: (2, 1),
            workload: (3, 1),
            deploy: (4, 1),
            rack: (1, 2),
            host_api: (2, 2),
            handshake: (3, 2),
            node_started: (4, 2),
            hall: (1, 3),
            power: (2, 3),
            disk: (3, 3),
        },
        x=40,
        y=cursor_y,
    )
    cursor_y += platform_height + GROUP_GAP
    change_nodes, _ = place_group(
        logical,
        change_group,
        {
            go_live: (0, 0),
            intake_work: (1, 0),
            digital_intake: (2, 0),
            live: (3, 0),
            manual_gap: (4, 0),
        },
        x=40,
        y=cursor_y,
        pad_bottom=100,
    )
    logical_nodes = {**business_nodes, **application_nodes, **platform_nodes, **change_nodes}
    logical_lines = draw(logical, relationships, logical_nodes)
    # A vertical stays in a column whose other row is empty, so it stops in the band.
    top = business_nodes[submitted]
    lane(between(logical_lines, channel_choice, register), band(top, 0))
    lane(between(logical_lines, register, intake_split), band(top, 1))
    lane(between(logical_lines, handling, register), band(top, 2))
    lane(
        between(logical_lines, register, handling),
        band(top, 3),
        source_x=business_nodes[register].cx + SHIFT,
        target_x=business_nodes[handling].cx + SHIFT,
    )
    lane(between(logical_lines, meeting, register), band(top, 4))
    # The second line between the service and the process stays just under those
    # two boxes. The board line runs one slot lower, so it clears that arc.
    lane(
        between(logical_lines, register, claims_service),
        band(business_nodes[register], 0),
        source_x=business_nodes[register].cx - SHIFT,
        target_x=business_nodes[claims_service].cx - SHIFT,
    )
    lane(between(logical_lines, board, register), band(business_nodes[register], 1))
    app_top = application_nodes[suite]
    lane(between(logical_lines, suite, claims_system), band(app_top, 0))
    lane(between(logical_lines, claims_api, app_service), band(app_top, 1))
    lane(between(logical_lines, claims_system, document_store), band(app_top, 2))
    lane(between(logical_lines, register_case, app_service), band(app_top, 3))
    case_row = application_nodes[register_case]
    lane(between(logical_lines, received, register_case), band(case_row, 0))
    lane(between(logical_lines, intake_join, register_case), band(case_row, 1))
    host_node = platform_nodes[host]
    lane(between(logical_lines, host, compute), band(host_node, 0))
    lane(
        between(logical_lines, compute, host),
        band(host_node, 1),
        source_x=platform_nodes[compute].cx + SHIFT,
        target_x=platform_nodes[host].cx + SHIFT,
    )
    lane(between(logical_lines, deploy, compute), band(platform_nodes[compute], 0))
    lane(
        between(logical_lines, deploy, package),
        band(platform_nodes[compute], 1),
        source_x=platform_nodes[deploy].cx - SHIFT,
        target_x=platform_nodes[package].cx - SHIFT,
    )
    lane(between(logical_lines, rack, compute), band(platform_nodes[compute], 2))
    # The return triggering sits beside the straight one, under the single row.
    lane(
        between(logical_lines, go_live, intake_work),
        band(change_nodes[go_live], 0),
        source_x=change_nodes[go_live].cx - SHIFT,
        target_x=change_nodes[intake_work].cx - SHIFT,
    )
    lane(between(logical_lines, live, intake_work), band(change_nodes[live], 1))
    check_routes(logical)

    present = {element.type for element in model.elements}
    missing = sorted(ELEMENT_TYPES - present)
    if missing:
        raise SystemExit("Model is missing element types: " + ", ".join(missing))
    used = {relationship.type for relationship in model.relationships}
    missing_relationships = sorted(RELATIONSHIP_TYPES - used)
    if missing_relationships:
        raise SystemExit("Model is missing relationship types: " + ", ".join(missing_relationships))

    return model


def stamp_archi_file(path: Path, model_id: str) -> None:
    """Give the project its own id, and set viewpoint ids Archi recognises."""
    with zipfile.ZipFile(path, "r") as archive:
        xml_bytes = archive.read("model.xml")
        extras = {
            info.filename: archive.read(info.filename)
            for info in archive.infolist()
            if info.filename != "model.xml"
        }

    root = etree.fromstring(xml_bytes)
    root.set("id", model_id)
    for element in root.iter("element"):
        if element.get(XSI_TYPE) != "archimate:ArchimateDiagramModel":
            continue
        viewpoint = ARCHI_VIEWPOINTS.get(element.get("name", ""))
        if viewpoint:
            element.set("viewpoint", viewpoint)

    rewritten = etree.tostring(root, xml_declaration=True, encoding="UTF-8", pretty_print=True)
    with zipfile.ZipFile(path, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        archive.writestr("model.xml", rewritten)
        for name, payload in extras.items():
            archive.writestr(name, payload)


def check_archi_file(path: Path) -> None:
    """Fail if a view points at a concept or a diagram object that is not in the file."""
    with zipfile.ZipFile(path) as archive:
        root = etree.fromstring(archive.read("model.xml"))

    concept_ids = set()
    relationship_ids = set()
    for element in root.iter("element"):
        kind = element.get(XSI_TYPE, "")
        identifier = element.get("id")
        if kind.endswith("Relationship"):
            relationship_ids.add(identifier)
            concept_ids.add(identifier)
        elif kind == "archimate:ArchimateDiagramModel":
            continue
        else:
            concept_ids.add(identifier)

    missing = []
    for child in root.iter("child"):
        referenced = child.get("archimateElement")
        if referenced and referenced not in concept_ids:
            missing.append(f"diagram object {child.get('id')} -> element {referenced}")
    for connection in root.iter("sourceConnection"):
        referenced = connection.get("archimateRelationship")
        if referenced and referenced not in relationship_ids:
            missing.append(f"connection {connection.get('id')} -> relationship {referenced}")
        for end in ("source", "target"):
            if connection.get(end) is None:
                missing.append(f"connection {connection.get('id')} has no {end}")
    if missing:
        raise SystemExit("Archi file has dangling view references:\n" + "\n".join(missing))

    viewpoints = [
        element.get("viewpoint")
        for element in root.iter("element")
        if element.get(XSI_TYPE) == "archimate:ArchimateDiagramModel"
    ]
    expected = set(ARCHI_VIEWPOINTS.values())
    if set(viewpoints) != expected:
        raise SystemExit(f"Viewpoint ids are {viewpoints}, expected {sorted(expected)}")

    nested = [child for child in root.iter("child") if child.find("child") is not None]
    if len(nested) < 7:
        raise SystemExit(f"Expected a grouping box on each landscape area, found {len(nested)} nested parents")


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    model = build()

    archi_path = OUT / "harbor-landscape.archimate"
    exchange_path = OUT / "harbor-landscape.xml"
    model.write(str(archi_path))
    model.write(str(exchange_path))
    stamp_archi_file(archi_path, model.uuid)
    check_archi_file(archi_path)

    reloaded = Model("reloaded")
    reloaded.read(str(archi_path))
    print(f"Wrote {archi_path}")
    print(f"Wrote {exchange_path}")
    print(
        f"Archi file reloads as {len(reloaded.elements)} elements, "
        f"{len(reloaded.relationships)} relationships, {len(reloaded.views)} views"
    )
    for view in reloaded.views:
        print(f"  {view.name}: {count_nodes(view)} nodes, {len(view.conns)} connections")


if __name__ == "__main__":
    main()
