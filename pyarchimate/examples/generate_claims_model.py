"""Generate an Archi project for a small claims landscape.

Run from this pyarchimate folder. On Windows with Git Bash, follow README.md
(pyenv-win for the Python version, then a venv). On macOS or Linux:

    python3 -m venv .venv
    .venv/bin/pip install -r requirements.txt
    .venv/bin/python examples/generate_claims_model.py

Then in Archi: File > Open, and choose

    examples/out/claims-handling.archimate

The same model is also written as Open Group exchange XML. In Archi that file
is File > Import > Open Exchange Format:

    examples/out/claims-handling.xml

pyArchimate checks each relationship against the ArchiMate matrix. Viewpoint
identifiers written on the diagrams are Archi's own ids (layered,
application_usage, technology). pyArchimate's viewpoint slugs are a different
vocabulary, so those ids are stamped onto the Archi file after export.

A connection is a straight line unless it has bendpoints. Elements that share
a row or a column are placed next to each other, so that line meets only its
two ends. A link that has to pass another element is drawn through the empty
band between the rows, on its own lane, so the lines do not stack.
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

# Archi viewpoint ids, from com.archimatetool.model/model/viewpoints.xml.
ARCHI_VIEWPOINTS = {
    "Layered view": "layered",
    "Application usage": "application_usage",
    "Technology": "technology",
}


def relate(model: Model, rel_type: str, source, target, name: str = ""):
    """Add a relationship and refuse a pair the ArchiMate matrix rejects."""
    check_valid_relationship(rel_type, source.type, target.type, raise_flg=True)
    return model.add_relationship(rel_type, source=source, target=target, name=name)


# Columns are 210px apart and elements are 148px wide, leaving a 62px gap.
# Rows leave an empty band above and below each band of elements. A bendpoint
# sits in one of those bands, never on top of an element.
W = 148
H = 58
COL = 210
ROW_ROLE = 40
ROW_PROCESS = 210
ROW_API = 380
ROW_APP = 520
ROW_TECH = 740


def at(col: int, row: int) -> tuple[int, int]:
    return 40 + col * COL, row


def put(view, element, col: int, row: int):
    x, y = at(col, row)
    return view.add(element, x=x, y=y, w=W, h=H)


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
    """Route a connection across an empty horizontal band.

    The line leaves the source vertically, crosses at ``y``, and enters the
    target vertically. ``source_x`` and ``target_x`` shift that crossing so
    two lines that share an element do not lie on the same pixels.
    """
    connection.add_bendpoint(
        Point(connection.source.cx if source_x is None else source_x, y),
        Point(connection.target.cx if target_x is None else target_x, y),
    )


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
    """Fail when a drawn line passes through an element that is not an end."""
    nodes = []

    def walk(items):
        for node in items:
            nodes.append(node)
            walk(node.nodes)

    walk(view.nodes)
    for connection in view.conns:
        points = [(connection.source.cx, connection.source.cy)]
        points.extend((point.x, point.y) for point in connection.bendpoints)
        points.append((connection.target.cx, connection.target.cy))
        for (x1, y1), (x2, y2) in zip(points, points[1:]):
            for node in nodes:
                if node is connection.source or node is connection.target:
                    continue
                if _segment_hits_rect(x1, y1, x2, y2, node.x + 2, node.y + 2, node.x + node.w - 2, node.y + node.h - 2):
                    raise SystemExit(
                        f"{view.name}: line {connection.source.name} -> {connection.target.name} "
                        f"crosses {node.name}"
                    )


def build() -> Model:
    model = Model("Claims handling")
    model.desc = (
        "Generated by examples/generate_claims_model.py. "
        "A policyholder registers a claim, a handler assesses it, "
        "and the claims applications run on one node."
    )

    customer = model.add(
        ArchiType.BusinessActor,
        "Customer",
        desc="Person who holds the policy and reports the loss.",
        folder="/Business/Claims",
    )
    policyholder = model.add(ArchiType.BusinessRole, "Policyholder", folder="/Business/Claims")
    handler = model.add(ArchiType.BusinessRole, "Claims handler", folder="/Business/Claims")
    register = model.add(ArchiType.BusinessProcess, "Register claim", folder="/Business/Claims")
    assess = model.add(ArchiType.BusinessProcess, "Assess claim", folder="/Business/Claims")
    claim_file = model.add(ArchiType.BusinessObject, "Claim file", folder="/Business/Claims")

    portal = model.add(ArchiType.ApplicationComponent, "Claims portal", folder="/Application/Claims")
    core = model.add(ArchiType.ApplicationComponent, "Claims core", folder="/Application/Claims")
    api = model.add(ArchiType.ApplicationInterface, "Claims API", folder="/Application/Claims")
    service = model.add(ArchiType.ApplicationService, "Claims service", folder="/Application/Claims")
    record = model.add(ArchiType.DataObject, "Claim record", folder="/Application/Claims")

    runtime = model.add(ArchiType.SystemSoftware, "Claims runtime", folder="/Technology/Claims")
    node = model.add(ArchiType.Node, "Claims node", folder="/Technology/Claims")
    platform = model.add(ArchiType.TechnologyService, "Claims platform", folder="/Technology/Claims")

    relationships = [
        relate(model, "Assignment", customer, policyholder),
        relate(model, "Assignment", handler, register),
        relate(model, "Assignment", handler, assess),
        relate(model, "Triggering", register, assess, name="claim registered"),
        relate(model, "Access", register, claim_file),
        relate(model, "Access", assess, claim_file),
        relate(model, "Flow", portal, core, name="submit claim"),
        relate(model, "Composition", core, api),
        relate(model, "Realization", core, service),
        relate(model, "Serving", api, policyholder),
        relate(model, "Serving", service, register, name="registers"),
        relate(model, "Serving", service, assess, name="assesses"),
        relate(model, "Access", core, record),
        relate(model, "Assignment", runtime, node),
        relate(model, "Realization", node, platform),
        relate(model, "Serving", platform, portal),
        relate(model, "Serving", platform, core),
    ]

    layered = model.add(
        ArchiType.View,
        "Layered view",
        desc="Business, application, and technology bands for the claims landscape.",
        folder="/Views/Claims",
    )
    nodes = {
        customer: put(layered, customer, 0, ROW_ROLE),
        policyholder: put(layered, policyholder, 1, ROW_ROLE),
        handler: put(layered, handler, 3, ROW_ROLE),
        register: put(layered, register, 2, ROW_PROCESS),
        assess: put(layered, assess, 3, ROW_PROCESS),
        claim_file: put(layered, claim_file, 4, ROW_PROCESS),
        api: put(layered, api, 3, ROW_API),
        portal: put(layered, portal, 2, ROW_APP),
        core: put(layered, core, 3, ROW_APP),
        service: put(layered, service, 4, ROW_APP),
        record: put(layered, record, 5, ROW_APP),
        runtime: put(layered, runtime, 0, ROW_TECH),
        node: put(layered, node, 1, ROW_TECH),
        platform: put(layered, platform, 2, ROW_TECH),
    }
    layered_lines = draw(layered, relationships, nodes)
    # Register claim sits between the handler and nothing on its row, but the
    # claim file is one element further along, so that access line goes over
    # the row rather than through Assess claim.
    lane(between(layered_lines, register, claim_file), ROW_PROCESS - 40)
    # The API is above the core. Its serving line to the policyholder leaves
    # sideways, then climbs the policyholder's column, so it misses Assess claim.
    lane(between(layered_lines, api, policyholder), ROW_API + H / 2)
    # Both serving lines leave the top of Claims service on separate tracks.
    service_node = nodes[service]
    lane(between(layered_lines, service, register), 300, source_x=service_node.cx - 18)
    lane(between(layered_lines, service, assess), 345, source_x=service_node.cx + 18)
    lane(between(layered_lines, core, record), ROW_APP + H + 40)
    lane(between(layered_lines, platform, core), ROW_APP + H + 80)
    check_routes(layered)

    usage = model.add(
        ArchiType.View,
        "Application usage",
        desc="How the policyholder and the handler reach the claims applications.",
        folder="/Views/Claims",
    )
    usage_nodes = {
        policyholder: put(usage, policyholder, 1, ROW_ROLE),
        handler: put(usage, handler, 3, ROW_ROLE),
        register: put(usage, register, 2, ROW_PROCESS),
        assess: put(usage, assess, 3, ROW_PROCESS),
        claim_file: put(usage, claim_file, 4, ROW_PROCESS),
        api: put(usage, api, 3, ROW_API),
        portal: put(usage, portal, 2, ROW_APP),
        core: put(usage, core, 3, ROW_APP),
        service: put(usage, service, 4, ROW_APP),
        record: put(usage, record, 5, ROW_APP),
    }
    usage_lines = draw(usage, relationships, usage_nodes)
    lane(between(usage_lines, register, claim_file), ROW_PROCESS - 40)
    lane(between(usage_lines, api, policyholder), ROW_API + H / 2)
    usage_service = usage_nodes[service]
    lane(between(usage_lines, service, register), 300, source_x=usage_service.cx - 18)
    lane(between(usage_lines, service, assess), 345, source_x=usage_service.cx + 18)
    lane(between(usage_lines, core, record), ROW_APP + H + 40)
    check_routes(usage)

    technology = model.add(
        ArchiType.View,
        "Technology",
        desc="The node and runtime that host the claims applications.",
        folder="/Views/Claims",
    )
    tech_nodes = {
        portal: put(technology, portal, 0, ROW_ROLE),
        core: put(technology, core, 1, ROW_ROLE),
        platform: put(technology, platform, 0, ROW_PROCESS),
        node: put(technology, node, 1, ROW_PROCESS),
        runtime: put(technology, runtime, 2, ROW_PROCESS),
    }
    tech_lines = draw(technology, relationships, tech_nodes)
    # Platform serves the core, which is one column over and one row up.
    # The bend keeps that line out of the portal.
    lane(between(tech_lines, platform, core), 150)
    check_routes(technology)

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


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    model = build()

    archi_path = OUT / "claims-handling.archimate"
    exchange_path = OUT / "claims-handling.xml"
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
        print(f"  {view.name}: {len(view.nodes)} nodes, {len(view.conns)} connections")


if __name__ == "__main__":
    main()
