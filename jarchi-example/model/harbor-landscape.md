# How harbor-landscape.json follows the model guide

`harbor-landscape.json` is the catalogue from [README.md](README.md). A Harbor
insurer settles motor claims. The file has one element of every ArchiMate
type the guide lists, one relationship of every type, and three views. Each
area is a Grouping, as in [parcel-delivery.md](parcel-delivery.md). The
canvas is not a flat stack of rows, as in [claims.md](claims.md).

The script reads the file and writes `out/harbor-landscape.archimate`.

```bash
cd jarchi-example
./run.sh model/harbor-landscape.json out/harbor-landscape.archimate
```

From `jarchi-example/windows`:

```bash
./run.sh ../model/harbor-landscape.json out/harbor-landscape.archimate
```

Archi opens that file with File > Open. The relationship directions below are
the ones Archi 5.3 accepts.

## File shape

| Field | Value in this file |
|---|---|
| `name` | `Harbor claims landscape`, stored as the Archi model name |
| `purpose` | The sentence about the insurer, the context, the conceptual view, and the logical view |
| `elements` | 71 concepts, covering all 63 types in the guide |
| `relationships` | 143 links. 61 of them are aggregations with `"draw": false` |
| `views` | Context diagram, Conceptual architecture, Logical architecture |

Every element id and relationship id is unique. A route names a relationship
id. The script copies each id onto the Archi object as the property `json-id`.

`folder` is `Harbor` on every element and every view. Archi creates a Harbor
subfolder under each top folder the file uses, and a Harbor subfolder under
Views. `documentation` is set only on the customer: "Person who holds the
policy and reports the loss."

Technology and Physical stay separate in the JSON. Archi stores both in
Technology & Physical. The JSON keeps the shorter layer name, which is the
rule in the guide.

## Elements

`type` is the kebab-case ArchiMate name. What each concept means is in the
[ArchiMate 3.2 Specification](https://pubs.opengroup.org/architecture/archimate32-doc/),
in the chapter for its layer. This file is the worked list behind the type
table in the guide: every row of that table appears here once. Business role
and application component appear twice, because the landscape needs a second
role and a second component. The three junctions are the three junction types.

Archi stores one Junction class. `or-junction` and `and-junction` are created
as `junction`, and the script then sets the junction type. `channel-choice`
becomes an Or junction, `intake-join` becomes an And junction, and
`intake-split` stays a plain junction.

### Business

| id | type | name |
|---|---|---|
| `customer` | `business-actor` | Customer |
| `policyholder` | `business-role` | Policyholder |
| `claimant` | `business-role` | Claimant |
| `claims-desk` | `business-interface` | Claims desk |
| `product` | `product` | Motor cover |
| `contract` | `contract` | Policy wording |
| `claim-notice` | `representation` | Claim notice |
| `board` | `business-collaboration` | Claims board |
| `register` | `business-process` | Register claim |
| `handling` | `business-function` | Case handling |
| `meeting` | `business-interaction` | Settlement meeting |
| `submitted` | `business-event` | Claim submitted |
| `claims-service` | `business-service` | Claims handling |
| `claim-file` | `business-object` | Claim file |

### Application

| id | type | name |
|---|---|---|
| `claims-system` | `application-component` | Claims system |
| `document-store` | `application-component` | Document store |
| `claims-api` | `application-interface` | Claims API |
| `dialogue` | `application-interaction` | Adjudication dialogue |
| `suite` | `application-collaboration` | Claims application suite |
| `validate` | `application-function` | Validate coverage |
| `register-case` | `application-process` | Register claim case |
| `received` | `application-event` | Claim received |
| `app-service` | `application-service` | Claims application service |
| `claim-record` | `data-object` | Claim record |

### Technology

| id | type | name |
|---|---|---|
| `host` | `node` | Claims host |
| `server` | `device` | App server |
| `link` | `path` | Data center link |
| `network` | `communication-network` | Harbor network |
| `runtime` | `system-software` | Claims runtime |
| `cluster` | `technology-collaboration` | Platform cluster |
| `host-api` | `technology-interface` | Host API |
| `workload` | `technology-function` | Run workload |
| `deploy` | `technology-process` | Deploy release |
| `handshake` | `technology-interaction` | Cluster handshake |
| `node-started` | `technology-event` | Node started |
| `compute` | `technology-service` | Compute service |
| `package` | `artifact` | Claims package |

### Physical

| id | type | name |
|---|---|---|
| `rack` | `equipment` | Rack |
| `hall` | `facility` | Harbor data hall |
| `power` | `distribution-network` | Power feed |
| `disk` | `material` | Spare disk |

### Motivation

| id | type | name |
|---|---|---|
| `director` | `stakeholder` | Claims director |
| `speed` | `driver` | Settlement speed |
| `cycle-gap` | `assessment` | Cycle time gap |
| `five-days` | `goal` | Settle in five days |
| `faster` | `outcome` | Faster settlement |
| `straight-through` | `principle` | Straight-through handling |
| `record-claim` | `requirement` | Record every claim |
| `retain` | `constraint` | Retain claim data |
| `meaning` | `meaning` | A claim is a request to pay |
| `trust` | `value` | Trust |

### Strategy

| id | type | name |
|---|---|---|
| `staff` | `resource` | Claims staff |
| `settlement` | `capability` | Claims settlement |
| `digitize` | `course-of-action` | Digitize intake |
| `claim-to-payment` | `value-stream` | Claim to payment |

### Implementation and Migration

| id | type | name |
|---|---|---|
| `intake-work` | `work-package` | Intake digitization |
| `digital-intake` | `deliverable` | Digital intake |
| `go-live` | `implementation-event` | Go live |
| `live` | `plateau` | Digital intake live |
| `manual-gap` | `gap` | Manual intake gap |

### Other

| id | type | name |
|---|---|---|
| `office` | `location` | Harbor office |
| `channel-choice` | `or-junction` | Channel choice |
| `intake-split` | `junction` | Intake split |
| `intake-join` | `and-junction` | Intake join |
| `enterprise` | `grouping` | Harbor claims enterprise |
| `motivation-group` | `grouping` | Motivation |
| `strategy-group` | `grouping` | Strategy |
| `business-group` | `grouping` | Business landscape |
| `application-group` | `grouping` | Application landscape |
| `platform-group` | `grouping` | Technology and physical landscape |
| `change-group` | `grouping` | Change roadmap |

## Relationships

The file uses every relationship type in the guide: composition, aggregation,
assignment, realization, serving, access, influence, association, triggering,
flow, and specialization. Three of them have a `name`. `customer-role` is
"plays", `claimant-role` is "is a", and `system-store` is "stores the notice".

`claimant-role` is the specialization. The claimant is a specialization of the
policyholder. `host-runtime` is a composition from the Node to the System
Software, which is the legal direction on Archi 5.3. Assignment from the
runtime back to the host is rejected. The claims file shows the other legal
form of that pair, an assignment that also leaves the node.

A line is drawn on a view only when both ends are on that view and `draw` is
not `false`. The same relationship can appear on only one of these views,
because each concept is placed on the view for its area.

### Grouping membership

Each grouping has one aggregation to each member, with `"draw": false`. The
counts follow the boxes:

| Grouping | Hidden aggregations | Members on the view |
|---|---|---|
| `enterprise` | 8 | 8 |
| `motivation-group` | 10 | 10 |
| `strategy-group` | 4 | 4 |
| `business-group` | 7 | 9 |
| `application-group` | 10 | 11 |
| `platform-group` | 17 | 17 |
| `change-group` | 5 | 5 |

`business-group` has two fewer aggregations than members, and
`application-group` has one fewer. The missing targets are the three
junctions. A junction carries one relationship type. `channel-choice` and
`intake-split` already have triggering. `intake-join` already has flow. An
aggregation from the grouping onto that junction is rejected on Archi 5.3.
The junction is still nested: its node sets `parent`, and the parent node
appears earlier in that view. The aggregation is left out. The six junction
links that remain are the real behavior:

| id | type | source → target |
|---|---|---|
| `event-choice` | triggering | submitted → channel-choice |
| `choice-process` | triggering | channel-choice → register |
| `process-split` | triggering | register → intake-split |
| `split-function` | triggering | intake-split → handling |
| `event-join` | flow | received → intake-join |
| `join-case` | flow | intake-join → register-case |

`split-function` stays a triggering. A flow from that junction to Case
handling is rejected. The boxes are neighbours, so the line is straight
either way. The type is what Archi 5.3 accepts.

## Views

Every view uses the viewpoint `layered` and the folder `Harbor`. `layered`
shows every concept, which this file needs because a single view mixes
business, application, technology, physical, and implementation concepts.

| View | Documentation in the file | Nodes | Routes |
|---|---|---|---|
| Context diagram | Customers, the motor product, and the Harbor office around the enterprise. | 9 | none |
| Conceptual architecture | Why the enterprise settles claims faster, and the capability it invests in. | 16 | 8 |
| Logical architecture | Business behavior, the applications that support it, the platform and premises underneath, and the change that digitizes intake. | 46 | 20 |

A grouping node sets `w` and `h`. A member sets `parent` and comes later in
`nodes`. Member `x` and `y` are relative to the grouping. A normal member
omits `w` and `h`, so they stay 148 by 58. A junction sets both to 20.

## Grid

The cell is the one in the guide:

```text
member x = 32 + column * 210
member y = 56 + row * 200
grouping width  = 32 * 2 + (columns - 1) * 210 + 148
grouping height = 56 + (rows - 1) * 200 + 58 + pad bottom
```

`columns` is the highest column plus one, and an empty cell still counts.
The business top row uses columns 0, 1, 3, 4, and 5. Column 2 of that row is
empty, so the width is still the width of six columns. Every grouping starts
at `x = 40`, so a column in one area lines up with the same column in the
area below. The next grouping starts at `previous y + previous height + 80`.

| Grouping | View position | Columns | Rows | pad bottom | Size |
|---|---|---|---|---|---|
| Harbor claims enterprise | (40, 40) | 4 | 2 | 48 | 842 by 362 |
| Motivation | (40, 40) | 6 | 2 | 80 | 1262 by 394 |
| Strategy | (40, 514) | 3 | 2 | 48 | 632 by 362 |
| Business landscape | (40, 40) | 6 | 2 | 100 | 1262 by 414 |
| Application landscape | (40, 534) | 6 | 3 | 48 | 1262 by 562 |
| Technology and physical landscape | (40, 1176) | 5 | 4 | 48 | 1052 by 762 |
| Change roadmap | (40, 2018) | 5 | 1 | 100 | 1052 by 214 |

Check Motivation. Six columns and two rows, with pad 80 because the lanes
under the second row need room inside the box:

```text
width  = 64 + 5 * 210 + 148 = 1262
height = 56 + 200 + 58 + 80 = 394
```

Strategy starts at `40 + 394 + 80 = 514`. On the logical view the same step
places Application landscape at `40 + 414 + 80 = 534`, the platform at
`534 + 562 + 80 = 1176`, and the change roadmap at `1176 + 762 + 80 = 2018`.

`pad bottom` is 48, the guide default, when no lane has to sit under the last
row. It is 80 on Motivation so the lane under Settle in five days stays
inside the box. It is 100 on the business landscape and the change roadmap
because several lanes run under the last row of those boxes.

### Junctions stay centred in the cell

A junction is 20 by 20, shifted so its centre matches the centre of a normal
element in the same cell:

```text
junction x = 32 + column * 210 + (148 - 20) / 2
junction y = 56 + row * 200 + (58 - 20) / 2
```

Channel choice is column 1, row 0 of the business landscape:

```text
x = 32 + 210 + 64 = 306
y = 56 + 19 = 75
```

That is the node in the file. Its centre on the view is
`40 + 306 + 10 = 356`, which is the same centre x as a 148-wide element in
column 1. A line along the row or the column still meets the circle at its
middle, so a neighbour of a junction can keep a straight line. Intake split
is the same shift in column 3. Intake join is the same shift in column 2 of
the application's third row, where `y = 56 + 2 * 200 + 19 = 475`.

### Cells

Column is across, row is down. The relative `x` and `y` in the file are the
formulas above.

Context, inside Harbor claims enterprise:

| | column 0 | column 1 | column 2 | column 3 |
|---|---|---|---|---|
| row 0 | customer | policyholder | claimant | claims-desk |
| row 1 | office | product | contract | claim-notice |

Conceptual, inside Motivation, then Strategy:

| | 0 | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|---|
| row 0 | director | speed | cycle-gap | faster | | |
| row 1 | five-days | straight-through | record-claim | retain | meaning | trust |

| | 0 | 1 | 2 |
|---|---|---|---|
| row 0 | settlement | staff | claim-to-payment |
| row 1 | | digitize | |

Logical, inside Business landscape. Column 2 of the top row is the empty cell
above Register claim:

| | 0 | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|---|
| row 0 | submitted | channel-choice | | intake-split | handling | meeting |
| row 1 | board | claims-service | register | | claim-file | |

Application landscape. Column 1 of the top row is empty:

| | 0 | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|---|
| row 0 | suite | | app-service | claims-system | claims-api | |
| row 1 | document-store | | | claim-record | validate | register-case |
| row 2 | | | intake-join | received | | dialogue |

Technology and physical landscape:

| | 0 | 1 | 2 | 3 | 4 |
|---|---|---|---|---|---|
| row 0 | cluster | host | server | link | network |
| row 1 | package | runtime | compute | workload | deploy |
| row 2 | | rack | host-api | handshake | node-started |
| row 3 | | hall | power | disk | |

Change roadmap is one row: go-live, intake-work, digital-intake, live,
manual-gap.

## Straight lines

A line stays straight when the two centres share a row or a column and no
other element sits between them. Those relationships are absent from
`routes`. A junction counts as sharing the row or the column, because its
centre was placed on the cell centre.

Two of these lines cross the gap between groupings. `capability-goal` runs
from Claims settlement up to Settle in five days. Both are column 0, the
groupings both start at x = 40, and the 80-pixel gap is empty on that
column. `app-process` does the same from Claims application service up to
Register claim.

### Context diagram

Four lines, and the view has no `routes` key.

| id | Alignment |
|---|---|
| `customer-role` | row 0, neighbouring columns |
| `claimant-role` | row 0, neighbouring columns |
| `customer-office` | column 0, one row apart |
| `product-contract` | row 1, neighbouring columns |

### Conceptual architecture

| id | Alignment |
|---|---|
| `director-speed` | top row, neighbouring columns |
| `speed-assessment` | top row, neighbouring columns |
| `assessment-outcome` | top row, neighbouring columns |
| `director-goal` | column 0, one row apart |
| `principle-goal` | second row, neighbouring columns |
| `principle-requirement` | second row, neighbouring columns |
| `constraint-requirement` | second row, neighbouring columns |
| `meaning-trust` | second row, neighbouring columns |
| `staff-capability` | strategy top row, neighbouring columns |
| `staff-course` | strategy column 1, one row apart |
| `capability-goal` | column 0, from Strategy up to Motivation |

### Logical architecture

| id | Alignment |
|---|---|
| `event-choice` | top business row, into the centred Or junction |
| `split-function` | top business row, out of the centred junction |
| `service-process` | second business row, neighbouring columns |
| `process-file` | second business row, and the cell between them is empty |
| `suite-store` | application column 0 |
| `system-api` | application top row, neighbouring columns |
| `system-service` | application top row, neighbouring columns |
| `system-record` | application column 3 |
| `function-record` | application second row, neighbouring columns |
| `case-function` | application second row, neighbouring columns |
| `event-join` | application third row, into the centred And junction |
| `dialogue-case` | application column 5 |
| `app-process` | column 2, from the application box up to the business box |
| `host-server` | platform top row |
| `host-runtime` | platform column 1 |
| `cluster-host` | platform top row |
| `server-link` | platform top row |
| `link-network` | platform top row |
| `package-runtime` | platform second row |
| `hostapi-compute` | platform column 2 |
| `workload-compute` | platform second row |
| `deploy-workload` | platform second row |
| `handshake-workload` | platform column 3 |
| `started-deploy` | platform column 4 |
| `hall-rack` | platform column 1 |
| `power-disk` | platform bottom row |
| `work-deliverable` | change row, neighbouring columns |
| `work-golive` | change row, neighbouring columns |
| `deliverable-plateau` | change row, neighbouring columns |
| `manual-gap-plateau` | change row, neighbouring columns |

`process-file` is straight because Register claim and the claim file share
the second business row and the cell between them on that row is empty.
Column 3 of that row has no element. The junction on the top row does not
sit between these two centres.

## Lanes

Every route is two points on one horizontal lane, in view coordinates. Add
the grouping's top-left to the member's relative position before using the
centre. The lane formula from the guide is:

```text
lane y = view y + height + 16 + slot * 22
centre x = view x + width / 2
```

Slot 0 is 16 pixels under the element. The next line in that band takes the
next slot. A line that would share a vertical with another line moves 18
pixels off the shared centre. For a nested element, `view y` is the grouping's
y plus the member's y.

### Conceptual architecture

The motivation top row has view y = 96 and bottom 154. The goal, Settle in
five days, has view y = 296 and bottom 354. Strategy starts at y = 514, so
Claims settlement has view y = 570 and bottom 628.

| id | Slot | Lane y | x shift | Why this lane |
|---|---|---|---|---|
| `director-assessment` | 0 under the director | 154 + 16 = 170 | none | The assessment is two columns away, with Settlement speed between them. |
| `speed-outcome` | 1 under Settlement speed | 154 + 16 + 22 = 192 | none | Faster settlement is two columns away, with the assessment between them. |
| `speed-goal` | 2 under Settlement speed | 154 + 16 + 44 = 214 | target centre minus 18, x = 128 | The goal's own column is already the straight `director-goal` line. |
| `assessment-goal` | 3 under Settlement speed | 154 + 16 + 66 = 236 | target centre minus 18, x = 128 | A third line into the same goal. |
| `outcome-goal` | 4 under Settlement speed | 154 + 16 + 88 = 258 | target centre minus 18, x = 128 | A fourth line into the same goal. 258 is still above the second row, which starts at 296. |
| `goal-requirement` | 0 under the goal | 354 + 16 = 370 | both centres plus 18 | Record every claim is two columns away. The shift keeps this line off the centre column of the goal. |
| `capability-stream` | 0 under Claims settlement | 628 + 16 = 644 | none | Claim to payment is two columns away, with Claims staff between them. |
| `course-capability` | 1 under Claims settlement | 644 + 22 = 666 | none | Digitize intake sits on the row below, one column to the right. The lane stays under the top row, above the course of action. |

The three lines into the goal share x = 128 on the target side and use three
different y values, 214, 236, and 258. They arrive beside the straight column
at x = 146 and they do not lie on each other.

### Logical architecture

**Under the business top row.** Claim submitted has view y = 96 and bottom
154. Five lanes use that band. The second row starts at view y = 296, so
slot 4 at 258 is still above it.

| id | Slot | Lane y | x shift |
|---|---|---|---|
| `choice-process` | 0 | 170 | none |
| `process-split` | 1 | 192 | none |
| `function-process` | 2 | 214 | none |
| `process-function` | 3 | 236 | both centres plus 18, so Register claim uses 584 and Case handling uses 1004 |
| `meeting-process` | 4 | 258 | none |

`process-function` and `function-process` are the two directions between
Register claim and Case handling. One of them leaves the centre line so the
pair does not share pixels. The claim file sits between them on the row
below, which is why neither line can cut the corner.

**Under Register claim.** Its view y is 296 and its bottom is 354.

| id | Slot | Lane y | x shift |
|---|---|---|---|
| `process-service` | 0 | 370 | both centres minus 18 |
| `board-process` | 1 | 392 | none |

The service line is shifted because the straight `service-process` already
uses the centre of Claims handling on that row. The board line is the next
slot down, so it clears that shifted line. Both lanes sit inside the box.
The bottom of the business landscape is `40 + 414 = 454`.

**Under the application top row.** Claims application suite has view y = 590
and bottom 648.

| id | Slot | Lane y | x shift |
|---|---|---|---|
| `suite-system` | 0 | 664 | none |
| `api-service` | 1 | 686 | none |
| `system-store` | 2 | 708 | none |
| `case-service` | 3 | 730 | none |

Each of these skips at least one element on the way: the empty column, the
claims system, or the whole second row. Slot 3 at 730 is still above the
second row, which starts at view y = 790.

**Under Register claim case.** Its view y is 790 and its bottom is 848.

| id | Slot | Lane y | x shift |
|---|---|---|---|
| `event-case` | 0 | 864 | none |
| `join-case` | 1 | 886 | none |

Claim received and the And junction are on the third row. The lanes run
under Register claim case, which is on the second row, so the lines climb
past Validate coverage without entering it. The application box continues
down to `534 + 562 = 1096`, which covers y = 886.

**Under the platform rows.** The host has view y = 1232 and bottom 1290.
Compute service has view y = 1432 and bottom 1490.

| id | Slot | Lane y | x shift |
|---|---|---|---|
| `host-compute` | 0 under the host | 1306 | none |
| `compute-host` | 1 under the host | 1328 | both centres plus 18 |
| `deploy-compute` | 0 under compute | 1506 | none |
| `deploy-package` | 1 under compute | 1528 | both centres minus 18 |
| `rack-compute` | 2 under compute | 1550 | none |

`host-compute` and `compute-host` are the two directions between the host and
the compute service. The return line is one slot lower and 18 pixels off both
centres. `deploy-package` is shifted the same way beside `deploy-compute`,
because both leave Deploy release. `rack-compute` is the third slot under
compute, and the rack is on the row below.

**Under the change row.** Go live has view y = 2074 and bottom 2132. The
change box starts at y = 2018 and is 214 tall, so it ends at 2232.

| id | Slot | Lane y | x shift |
|---|---|---|---|
| `golive-work` | 0 | 2148 | both centres minus 18 |
| `plateau-work` | 1 | 2170 | none |

`work-golive` is already the straight line between those neighbours. The
routed line is the other triggering, drawn beside it. The plateau line uses
the next slot so it clears that pair on the way to Intake digitization.
Pad 100 on this one-row box is what keeps y = 2170 inside the grouping.

## What the polyline check sees

Read a routed line as source centre, then the two points, then target
centre. `choice-process` leaves the Or junction at its cell centre
(356, 125), drops to (356, 170), crosses to Register claim's centre, and
enters that process. The drop stays in the empty band under the top row.
`speed-goal` arrives at x = 128, eighteen pixels left of the goal, so it
does not ride the director's column. A segment may cross the grouping that
contains its own element. It does not pass through any other element.
