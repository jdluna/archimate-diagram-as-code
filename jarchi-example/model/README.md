# Writing a JSON model

`scripts/create-from-json.ajs` reads one JSON file and creates the elements,
relationships, and views in an empty Archi model. Copy `claims.json` when the
diagram is a stack of rows on the canvas. [claims.md](claims.md) walks through
that file against the rules in this guide. Copy `parcel-delivery.json` when
each area is a Grouping with its concepts nested inside.
[parcel-delivery.md](parcel-delivery.md) walks through that file.
`harbor-landscape.json` contains one element of every ArchiMate type, so it
is the catalogue of type names. [harbor-landscape.md](harbor-landscape.md)
walks through that file.

```bash
cd jarchi-example
./run.sh model/your-model.json out/your-model.archimate
```

From `jarchi-example/windows`, the model path is one folder up:

```bash
./run.sh ../model/your-model.json out/your-model.archimate
```

Archi opens the `.archimate` file with File > Open. The Windows scripts use
Archi 5.3. A relationship that Archi 5.10 accepts can still be rejected there.
The rules in [Relationships](#relationships) are the 5.3 rules.

## File shape

```json
{
  "name": "Parcel delivery",
  "purpose": "One sentence that Archi stores on the model.",
  "elements": [],
  "relationships": [],
  "views": []
}
```

`name` becomes the model name. `purpose` is optional and becomes the model
purpose. Every `id` in `elements` and `relationships` is unique inside the
file. A relationship and a route refer to those ids. The script stores each
id on the Archi object as the property `json-id`.

## Elements

| Field | Required | Meaning |
|---|---|---|
| `id` | yes | Stable id used by relationships, nodes, and routes |
| `type` | yes | Archi concept name, kebab-case |
| `name` | yes | Label drawn on the element |
| `layer` | yes | Archi top folder, listed below |
| `folder` | no | Subfolder created under that top folder |
| `documentation` | no | Archi documentation text |
| `fillColor` | no | Fill of every box of this element, `#rrggbb` |
| `figure` | no | `default` or `alternate` for every box of this element |

`fillColor` paints the box on each view that places the element. Archi stores
the fill on the box, not on the concept, so the same element can still take a
different colour on one view. The value is `#` plus six hex digits, for
example `#fff2cc`. Leave it out and the box keeps Archi's default fill for
that concept.

```json
{ "id": "portal", "type": "application-component", "name": "Claims portal", "layer": "Application", "fillColor": "#c5e8ff" }
```

`figure` chooses which of Archi's two figures is drawn. Archi stores it on
the box, so a node can use the other figure on one view. Leave it out, or set
`default`, and the box is the figure Archi uses for a new element: a
rectangle, or a rounded rectangle, with the concept's icon in the corner.
`alternate` is the other figure in Archi's Figure property. That outline is
the concept's own shape: a business actor becomes the person, a business
process becomes the chevron, an application component grows the two tabs on
its side, and a grouping grows the tab along the top. A junction is only the
circle, so `alternate` is rejected for `junction`, `or-junction`, and
`and-junction`.

```json
{ "id": "register", "type": "business-process", "name": "Register claim", "layer": "Business", "figure": "alternate" }
```

`layer` is one of `Business`, `Application`, `Technology`, `Physical`,
`Strategy`, `Motivation`, `Implementation & Migration`, or `Other`. Archi
keeps Technology and Physical together in the folder `Technology & Physical`.
The JSON still uses the shorter layer name. A Grouping, a Location, and a
Junction belong in `Other`.

`type` is the name jArchi passes to `model.createElement`. It is the ArchiMate
concept with spaces turned into hyphens: a Business Actor is `business-actor`,
an Application Component is `application-component`. The Open Group defines
what each concept means in the
[ArchiMate 3.2 Specification](https://pubs.opengroup.org/architecture/archimate32-doc/).
The chapters that match the folders are Motivation, Strategy, Business Layer,
Application Layer, Technology Layer, Physical Elements, and Implementation and
Migration. Relationships are in the Relationships chapter, and viewpoints are
in the Architecture Views and Viewpoints chapter.

Archi stores one Junction class. `or-junction` and `and-junction` are created
as `junction`, and the script then sets the junction type to `or` or `and`.

`harbor-landscape.json` has every concept the samples use:

| Folder | Types |
|---|---|
| Business | `business-actor`, `business-role`, `business-collaboration`, `business-interface`, `business-process`, `business-function`, `business-interaction`, `business-event`, `business-service`, `business-object`, `contract`, `representation`, `product` |
| Application | `application-component`, `application-collaboration`, `application-interface`, `application-process`, `application-function`, `application-interaction`, `application-event`, `application-service`, `data-object` |
| Technology | `node`, `device`, `system-software`, `technology-collaboration`, `technology-interface`, `path`, `communication-network`, `technology-process`, `technology-function`, `technology-interaction`, `technology-event`, `technology-service`, `artifact` |
| Physical | `equipment`, `facility`, `distribution-network`, `material` |
| Motivation | `stakeholder`, `driver`, `assessment`, `goal`, `outcome`, `principle`, `requirement`, `constraint`, `meaning`, `value` |
| Strategy | `resource`, `capability`, `course-of-action`, `value-stream` |
| Implementation & Migration | `work-package`, `deliverable`, `implementation-event`, `plateau`, `gap` |
| Other | `grouping`, `location`, `junction`, `or-junction`, `and-junction` |

## Relationships

| Field | Required | Meaning |
|---|---|---|
| `id` | yes | Id used by a route |
| `type` | yes | Relationship name, kebab-case, ending in `-relationship` |
| `source` | yes | Element id the line leaves |
| `target` | yes | Element id the line enters |
| `name` | no | Label on the line |
| `draw` | no | `false` keeps the relationship in the model and off every view |

The type names are `composition-relationship`, `aggregation-relationship`,
`assignment-relationship`, `realization-relationship`,
`serving-relationship`, `access-relationship`, `influence-relationship`,
`association-relationship`, `triggering-relationship`, `flow-relationship`,
and `specialization-relationship`. Which pairs are legal is the ArchiMate
relationship table, and Archi enforces it. The script stops when Archi
rejects a pair. Direction is part of the rule: swap `source` and `target`
when the reverse direction is the one the table allows.

Two rules decide whether a Windows run with Archi 5.3 succeeds:

- A Node is the source of a relationship to System Software. `claims.json`
  assigns `node` to `runtime`. A composition from the node to the system
  software, as in `parcel-delivery.json`, is the other legal direction.
  Assignment from the system software back to the node is rejected.
- A Junction carries one relationship type. Once it has a Triggering or a
  Flow, a later Aggregation from its Grouping onto that junction is rejected.
  Nest the junction with `parent` and leave the aggregation out.
  `harbor-landscape.json` does this for the channel, intake, and join
  junctions. A Flow from a junction to a Business Function is also rejected
  there; that link stays a Triggering.

A line is drawn on a view only when both of its elements are placed on that
view. The same relationship can appear on several views. `"draw": false` is
how a Grouping records membership: one Aggregation from the grouping to each
member, with no line on top of the nested boxes.

## Views

| Field | Required | Meaning |
|---|---|---|
| `name` | yes | Diagram name |
| `viewpoint` | no | Archi viewpoint id |
| `folder` | no | Subfolder under Views. The default is `Generated` |
| `documentation` | no | Text stored on the view |
| `nodes` | yes | Elements placed on the view, in order |
| `routes` | no | Bendpoints for lines that would otherwise cross an element |

A node is `{ "element": "portal", "x": 460, "y": 520 }`. `w` and `h` default
to 148 and 58. Set them on a Grouping, and set them to 20 and 20 on a
Junction. `parent` names another element already placed earlier in the same
`nodes` array. The child is added inside that diagram object, and its `x`
and `y` are measured from the parent's top-left. A node `fillColor` replaces
the element colour for that box only. A node `figure` does the same for the
shape. `default` on a node puts that one box back on Archi's usual figure
when the element itself is `alternate`.

```json
{ "element": "portal", "x": 460, "y": 520, "fillColor": "#ffe0c2", "figure": "alternate" }
```

`viewpoint` is an id from Archi's `viewpoints.xml`. The ids are `organization`,
`business_process_cooperation`, `product`, `application_cooperation`,
`application_structure`, `application_usage`, `implementation_deployment`,
`technology`, `technology_usage`, `information_structure`,
`service_realization`, `physical`, `stakeholder`, `goal_realization`,
`requirements_realization`, `motivation`, `strategy`, `capability`,
`value_stream`, `outcome_realization`, `resource`, `project`, `migration`,
`implementation_migration`, and `layered`. `layered` shows every concept, which
is why `parcel-delivery.json` uses it for all four diagrams. A narrower
viewpoint still accepts the file, and the samples place only the concepts that
viewpoint is meant to show: `claims.json` uses `application_usage` and
`technology` on the two smaller views.

## Grid

Every sample uses the same cell. An element is 148 by 58. The next column
starts 210 pixels to the right, so the gap beside an element is 62. The next
row starts 200 pixels below, so the gap under an element is 142. That gap is
where a long line travels. A Junction is a 20 pixel circle centred in the
same cell, so a line along the row or the column still meets the circle at
its middle.

```text
W = 148
H = 58
COL = 210
ROW = 200
PAD_X = 32
PAD_TOP = 56
PAD_BOTTOM = 48
GROUP_GAP = 80
SHIFT = 18
```

Give each element a column and a row, both starting at 0. Then turn that pair
into pixels with one of the two patterns below. Leave a column empty when a
line needs a vertical gap, the way `handler` sits at column 3 in
`claims.json` while column 2 on the top row is empty.

### Flat bands

Use this when the view has no Grouping. `claims.json` is the example. The
canvas origin is `(40, 40)`.

```text
x = 40 + column * 210
y = row top
```

The claims rows are roles at `y = 40`, processes at `210`, the API at `380`,
applications at `520`, and technology at `740`. Column 0 is `x = 40`, column 1
is `250`, column 2 is `460`, and each further column adds 210. The technology
row is lower than a strict 200-pixel step so the lane under the applications
has room.

A node on a flat view has no `parent` and no `w` or `h`. The defaults apply.

### Areas inside a Grouping

Use this when a view is a context box, a motivation box, or a stack of layer
boxes. `parcel-delivery.json` and `harbor-landscape.json` are the examples.
The grouping is placed on the view. Each member comes later in `nodes`, with
`parent` set to the grouping id. Member `x` and `y` are relative to the
grouping, so they do not include the grouping's own position.

```text
columns = highest column + 1
rows = highest row + 1
grouping width  = 32 * 2 + (columns - 1) * 210 + 148
grouping height = 56 + (rows - 1) * 200 + 58 + pad bottom

member x = 32 + column * 210
member y = 56 + row * 200
```

`pad bottom` is 48 when nothing is routed under the last row. Raise it when a
lane has to pass below that row: the motivation grouping in
`parcel-delivery.json` uses 100, and the depot platform uses 80. The next
grouping down starts at `previous y + previous height + 80`. Start every
grouping at the same `x` when the columns should line up from one area to the
next.

A Junction in cell `(column, row)` is shifted so its centre matches the cell:

```text
junction x = 32 + column * 210 + (148 - 20) / 2
junction y = 56 + row * 200 + (58 - 20) / 2
junction w = 20
junction h = 20
```

An actor that stands outside a context box keeps the column of the concept it
relates to. In the parcel system context, the customer is on the sender's
column and the carrier is on the depot's column, both at `y = 40`, and the
enterprise grouping starts at `y = 200`.

Add one Aggregation with `"draw": false` from the grouping to each member.
That records the membership in the model. The nested box is what the reader
sees.

### Straight lines

Two elements on the same row, or the same column, with no other element
between them, keep the straight line Archi draws. Leave that relationship out
of `routes`. The booking service above the book process in
`parcel-delivery.json` is this case: the columns match, the line runs through
the gap between the groupings, and there is no route entry.

### Lanes

Any other line gets a `routes` entry with two points. Both points sit on one
horizontal lane in an empty band. The line leaves the source toward the first
point, crosses to the second point, and enters the target. The points are
view coordinates. A nested element's position on the view is the grouping's
top-left plus the member's `x` and `y`.

```text
centre x = view x + width / 2
centre y = view y + height / 2
lane y   = view y + height + 16 + slot * 22

points = [
  { "x": source centre x, "y": lane y },
  { "x": target centre x, "y": lane y }
]
```

`slot` starts at 0. The next line that uses the same band takes the next
slot, 22 pixels lower, so the two lines do not lie on the same pixels. When
two lines also share an element, move one of them 18 pixels off that
element's centre (`SHIFT`). A line into an element uses `centre x - 18` on
the target. A line out of an element uses `centre x + 18` on the source.
`claims.json` does this for the two lines that leave the claims service:
one crosses at `y = 300` on `centre x - 18`, the other at `y = 345` on
`centre x + 18`.

Worked from the parcel conceptual view. The motivation grouping is at
`(40, 40)`. Delivery speed is column 1, row 0, so its box on the view starts
at `(40 + 242, 40 + 56) = (282, 96)` and its centre x is `282 + 74 = 356`.
Deliver next day is column 0, row 1, centre x `40 + 32 + 74 = 146`. The lane
under the first row is `96 + 58 + 16 = 170`. The route for `speed-goal` is
therefore `(356, 170)` then `(146, 170)`.

The same arithmetic fixes a lane under a grouping. The strategy grouping
starts below the motivation box. A lane under its last row uses that member's
view y, plus its height, plus 16, plus `slot * 22`.

Check the result by reading the line as a polyline from source centre,
through the points, to target centre. A segment may start or end inside the
grouping that contains its own element. It should not pass through any other
element. When it does, move the lane into a gap or shift it by 18 pixels onto
a free track.
