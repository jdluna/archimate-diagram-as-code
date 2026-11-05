# How claims.json follows the model guide

`claims.json` is the flat-band example from [README.md](README.md). A
policyholder registers a claim, a handler assesses it, and the claims
applications run on one node. The canvas is five rows of elements. There is
no Grouping, so nothing in the file uses `parent`, an explicit `w` or `h`,
a junction, or `"draw": false`.

The script reads the file and writes `out/claims-handling.archimate`.

```bash
cd jarchi-example
./run.sh model/claims.json out/claims-handling.archimate
```

From `jarchi-example/windows`:

```bash
./run.sh ../model/claims.json out/claims-handling.archimate
```

Archi opens that file with File > Open. The relationship directions below are
the ones Archi 5.3 accepts.

## File shape

The file is the three arrays from the guide, plus the two model fields.

| Field | Value in this file |
|---|---|
| `name` | `Claims handling`, stored as the Archi model name |
| `purpose` | The sentence about the policyholder, the handler, and the node |
| `elements` | 14 concepts |
| `relationships` | 17 links |
| `views` | Layered view, Application usage, Technology |

Every element id and relationship id is unique. A route names a relationship
id. The script copies each id onto the Archi object as the property `json-id`,
so `customer`, `register-file`, and the other ids can be found again after
the model is generated.

## Elements

Each element has `id`, `type`, `name`, `layer`, and `folder`. `folder` is
`Claims` on every element, so Archi creates a Claims subfolder under Business,
under Application, and under Technology & Physical. The JSON keeps the layer
name `Technology`. Archi stores that layer in Technology & Physical, as the
guide describes.

`documentation` is set only on the customer: "Person who holds the policy and
reports the loss." The other elements have no documentation field.

The types are the kebab-case ArchiMate names. What each one means is in the
[ArchiMate 3.2 Specification](https://pubs.opengroup.org/architecture/archimate32-doc/),
in the Business Layer, Application Layer, and Technology Layer chapters.

| id | type | name | layer |
|---|---|---|---|
| `customer` | `business-actor` | Customer | Business |
| `policyholder` | `business-role` | Policyholder | Business |
| `handler` | `business-role` | Claims handler | Business |
| `register` | `business-process` | Register claim | Business |
| `assess` | `business-process` | Assess claim | Business |
| `claim-file` | `business-object` | Claim file | Business |
| `portal` | `application-component` | Claims portal | Application |
| `core` | `application-component` | Claims core | Application |
| `api` | `application-interface` | Claims API | Application |
| `service` | `application-service` | Claims service | Application |
| `record` | `data-object` | Claim record | Application |
| `runtime` | `system-software` | Claims runtime | Technology |
| `node` | `node` | Claims node | Technology |
| `platform` | `technology-service` | Claims platform | Technology |

This file uses 11 of the concept names listed in the guide. It has no
Motivation, Strategy, Physical, or Implementation element, and no Grouping,
Location, or Junction.

## Relationships

A relationship has `id`, `type`, `source`, and `target`. Four of them also
have `name`, which Archi draws on the line. None set `draw`, so every
relationship may be drawn. The script draws it on a view only when both ends
are placed on that view, which is why the same id appears on more than one
diagram and why several ids appear on only one.

The type is one of the names in the guide. Direction follows the ArchiMate
relationship table. The pair that Archi 5.3 is strict about is `node-runtime`:
the source is the Node and the target is the System Software. Assignment from
`runtime` back to `node` is rejected.

There is no junction, so the junction rule in the guide does not come up. There
is no Grouping, so there is no aggregation with `"draw": false`.

| id | type | source → target | name | Drawn on |
|---|---|---|---|---|
| `customer-role` | assignment | customer → policyholder | | Layered view |
| `handler-register` | assignment | handler → register | | Layered view, Application usage |
| `handler-assess` | assignment | handler → assess | | Layered view, Application usage |
| `register-triggers-assess` | triggering | register → assess | claim registered | Layered view, Application usage |
| `register-file` | access | register → claim-file | | Layered view, Application usage |
| `assess-file` | access | assess → claim-file | | Layered view, Application usage |
| `portal-core` | flow | portal → core | submit claim | all three views |
| `core-api` | composition | core → api | | Layered view, Application usage |
| `core-service` | realization | core → service | | Layered view, Application usage |
| `api-policyholder` | serving | api → policyholder | | Layered view, Application usage |
| `service-register` | serving | service → register | registers | Layered view, Application usage |
| `service-assess` | serving | service → assess | assesses | Layered view, Application usage |
| `core-record` | access | core → record | | Layered view, Application usage |
| `node-runtime` | assignment | node → runtime | | Layered view, Technology |
| `node-platform` | realization | node → platform | | Layered view, Technology |
| `platform-portal` | serving | platform → portal | | Layered view, Technology |
| `platform-core` | serving | platform → core | | Layered view, Technology |

`customer-role` is missing from Application usage because that view does not
place `customer`. The four technology relationships are missing from
Application usage because that view does not place `node`, `runtime`, or
`platform`. The business and application relationships other than `portal-core`
are missing from Technology because that view only places `portal`, `core`,
`platform`, `node`, and `runtime`.

## Views

Each view has `name`, `viewpoint`, `folder`, `documentation`, `nodes`, and,
where a line needs a bend, `routes`. `folder` is `Claims`, so the diagrams
land in a Claims subfolder under Views.

A node is an element id plus `x` and `y`. Width and height are omitted, so
the script uses the guide defaults, 148 by 58. No node has `parent`, because
nothing is nested.

| View | viewpoint | What it places |
|---|---|---|
| Layered view | `layered` | All 14 elements. This viewpoint shows every concept. |
| Application usage | `application_usage` | The two roles, the two processes, the claim file, and the five application concepts. The viewpoint covers business roles, processes, and objects together with the application layer. The customer actor is left off so the diagram starts at the policyholder. Technology is left off because this viewpoint does not include it. |
| Technology | `technology` | The portal, the core, the platform, the node, and the runtime. The viewpoint is the technology picture. The portal and the core are on it so the hosting lines have an application to land on. |

The documentation strings are the view descriptions in the file: the layered
bands, how the policyholder and the handler reach the applications, and the
node and runtime that host those applications.

## Grid

The cell is the one in the guide. An element is 148 by 58. The next column is
210 to the right, so

```text
x = 40 + column * 210
```

| Column | x |
|---|---|
| 0 | 40 |
| 1 | 250 |
| 2 | 460 |
| 3 | 670 |
| 4 | 880 |
| 5 | 1090 |

On the Layered view and on Application usage the row tops are fixed. They are
not a strict step of 200. The technology row is at 740 rather than 720 so the
two lanes under the application row, at 618 and 658, stay above that row.

| Row | y | Layered view | Application usage |
|---|---|---|---|
| Roles | 40 | customer col 0, policyholder col 1, handler col 3 | policyholder col 1, handler col 3 |
| Processes | 210 | register col 2, assess col 3, claim-file col 4 | the same three |
| API | 380 | api col 3 | api col 3 |
| Applications | 520 | portal col 2, core col 3, service col 4, record col 5 | the same four |
| Technology | 740 | runtime col 0, node col 1, platform col 2 | this row is omitted |

Column 2 of the role row is empty on purpose. The handler sits at column 3,
so the line down to Register claim can cross that empty cell, and the line
down to Assess claim stays on column 3. That is the empty-column pattern in
the guide.

Check one cell. Assess claim is column 3 of the process row:

```text
x = 40 + 3 * 210 = 670
y = 210
```

That is the node in the file. Claims service is column 4 of the application
row, `x = 40 + 4 * 210 = 880`, `y = 520`. Every other node on these two views
is the same formula. The centre used by a route is `x + 74`, because the
default width is 148.

The Technology view uses the same formula on a smaller grid. Its rows reuse
y = 40 and y = 210.

| Element | Column | Row y | x |
|---|---|---|---|
| portal | 0 | 40 | 40 |
| core | 1 | 40 | 250 |
| platform | 0 | 210 | 40 |
| node | 1 | 210 | 250 |
| runtime | 2 | 210 | 460 |

## Straight lines

A line stays straight when the two elements share a row or a column and no
other element sits between them. Those relationships are absent from `routes`.
The centre of a box is `(x + 74, y + 29)`.

On the Layered view the straight lines are:

| Relationship | Why it is straight |
|---|---|
| `customer-role` | Both on y = 40, in columns 0 and 1, with nothing between them. |
| `handler-assess` | Both on x = 670. The gap from the bottom of the handler (y = 98) to the top of Assess claim (y = 210) is empty. |
| `handler-register` | The handler centre is (744, 69) and Register claim is (534, 239). Column 2 of the role row is empty, and the line reaches Register claim to the left of Assess claim, whose box starts at x = 670. |
| `register-triggers-assess` | Both on y = 210, in neighbouring columns 2 and 3. |
| `assess-file` | Both on y = 210, in neighbouring columns 3 and 4. |
| `portal-core` | Both on y = 520, in neighbouring columns 2 and 3. |
| `core-api` | Both on x = 670. The API bottom is y = 438 and the core top is y = 520, and that gap is empty. |
| `core-service` | Both on y = 520, in neighbouring columns 3 and 4. |
| `node-runtime` | Both on y = 740, in neighbouring columns 0 and 1. |
| `node-platform` | Both on y = 740, in neighbouring columns 1 and 2. |
| `platform-portal` | Both on x = 460. Register claim is higher up that column, not between the portal and the platform. |

Application usage keeps the same coordinates for the elements it shares, so
the same straight lines are drawn there, except `customer-role` and the
technology lines, whose ends are not both on that view.

On the Technology view the straight lines are `portal-core` along y = 40,
`platform-portal` along x = 40, `node-platform` along y = 210, and
`node-runtime` along y = 210. Each pair is on one row or one column with
nothing between the boxes.

## Lanes

A line that would pass through another element has a `routes` entry with two
points. Both points are view coordinates on one horizontal lane. The line
drops from the source centre to the first point, crosses to the second, and
enters the target. Because these views are flat, the view coordinate is the
node's own `x` and `y`. There is no grouping origin to add.

The two lines that leave Claims service share that element, so they use the
guide's 18-pixel shift and two different y values. One leaves at
`centre x - 18`. The other leaves at `centre x + 18`.

### Layered view

Six routes. Application usage repeats the first five with the same numbers,
because those ten elements sit on the same cells. `platform-core` is not
repeated there.

**`register-file`.** Register claim and the claim file are on the same row,
but Assess claim sits between them, so a straight line would cross it. The
lane is 40 pixels above the process row.

```text
lane y = 210 - 40 = 170
register centre x = 460 + 74 = 534
claim-file centre x = 880 + 74 = 954
points = (534, 170), (954, 170)
```

The role row ends at y = 98, so y = 170 is in the empty band between the
roles and the processes.

**`api-policyholder`.** The API is on column 3 and the policyholder is on
column 1, two rows above. A straight diagonal would meet Assess claim. The
lane runs at the API's vertical centre, then climbs the policyholder's column.
That column is empty from the role row down to the API row.

```text
lane y = 380 + 58 / 2 = 409
api centre x = 670 + 74 = 744
policyholder centre x = 250 + 74 = 324
points = (744, 409), (324, 409)
```

**`service-register`.** Claims service is column 4 of the application row,
centre x = 880 + 74 = 954. Register claim is column 2 of the process row.
The line leaves 18 pixels to the left of the service centre and crosses the
band between the process row and the API row. The process row ends at
y = 268 and the API row starts at y = 380.

```text
lane y = 300
source x = 954 - 18 = 936
register centre x = 534
points = (936, 300), (534, 300)
```

**`service-assess`.** The second line out of the same service uses the other
side of the centre and a lower lane, so the two lines do not share pixels.
Assess claim is on column 3, centre x = 744.

```text
lane y = 345
source x = 954 + 18 = 972
points = (972, 345), (744, 345)
```

345 is still above the API row. The gap between 300 and 345 is the claims
form of two slots in one band. The guide's later examples step slots by 22
pixels with `lane y = view y + height + 16 + slot * 22`. This file picks the
two y values directly inside the gap.

**`core-record`.** The core and the claim record share the application row,
with Claims service between them. The lane is 40 pixels under that row.

```text
lane y = 520 + 58 + 40 = 618
core centre x = 670 + 74 = 744
record centre x = 1090 + 74 = 1164
points = (744, 618), (1164, 618)
```

The application row ends at y = 578. The technology row starts at y = 740.
y = 618 sits in that gap and clears the service box.

**`platform-core`.** The platform is column 2 of the technology row and the
core is column 3 of the application row. The portal already occupies column 2
on the application row, so the line cannot climb that column. It crosses 80
pixels under the application row, 40 pixels below the `core-record` lane.

```text
lane y = 520 + 58 + 80 = 658
platform centre x = 460 + 74 = 534
core centre x = 744
points = (534, 658), (744, 658)
```

658 is still above the technology row at 740. That is why this row is at 740
rather than one strict 200-pixel step below 520.

### Technology view

One route, **`platform-core`**, with different coordinates because the boxes
moved. The platform is now column 0 at y = 210, centre (114, 239). The core
is column 1 at y = 40, centre (324, 69). The portal occupies column 0 at
y = 40, so a vertical line up from the platform would enter the portal. The
lane sits in the gap between those rows. The upper row ends at y = 98 and the
lower row starts at y = 210.

```text
lane y = 150
platform centre x = 40 + 74 = 114
core centre x = 250 + 74 = 324
points = (114, 150), (324, 150)
```

The line rises from the platform to y = 150, crosses to the core's column,
and enters the core. It stays below the portal.

## What the polyline check sees

Read each routed line as source centre, then the two points, then target
centre. On the Layered view, `register-file` leaves (534, 239), goes up to
(534, 170), crosses to (954, 170), and comes down into the claim file at
(954, 239). That path goes over Assess claim. `service-register` leaves the
service at x = 936 rather than through its centre, crosses at y = 300, and
drops into Register claim, missing the API and Assess claim. The same reading
fixes the other four layered routes and the single Technology route. A segment
ends in its own element and does not pass through any other box.
