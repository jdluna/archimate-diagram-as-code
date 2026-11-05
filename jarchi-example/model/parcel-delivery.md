# How parcel-delivery.json follows the model guide

`parcel-delivery.json` is the grouped example from [README.md](README.md). A
parcel company takes a booking from a sender, sorts the parcel, and runs the
depot on one host. Each area is a Grouping. The concepts sit inside that box,
and a long line travels in the gap between the rows. [claims.md](claims.md) is
the same guide applied to a flat canvas. This file is the other pattern.

The script reads the file and writes `out/parcel-delivery.archimate`.

```bash
cd jarchi-example
./run.sh model/parcel-delivery.json out/parcel-delivery.archimate
```

From `jarchi-example/windows`:

```bash
./run.sh ../model/parcel-delivery.json out/parcel-delivery.archimate
```

Archi opens that file with File > Open. The relationship directions below are
the ones Archi 5.3 accepts.

## File shape

| Field | Value in this file |
|---|---|
| `name` | `Parcel delivery`, stored as the Archi model name |
| `purpose` | The sentence about the booking, the sort, and the depot host |
| `elements` | 34 concepts, including 6 groupings |
| `relationships` | 57 links, of which 27 are aggregations with `"draw": false` |
| `views` | Conceptual architecture, System context, Logical architecture, Infrastructure |

Every element id and relationship id is unique. A route names a relationship
id. The script copies each id onto the Archi object as the property `json-id`.

## Elements

Every element has `id`, `type`, `name`, `layer`, and `folder`. `folder` is
`Parcel` on every element, so Archi creates a Parcel subfolder under each top
folder the file uses. `documentation` is set only on the customer: "Person who
sends a parcel."

`layer` selects the Archi folder. Groupings and the City depot are `Other`.
The host, the runtime, the scanner, the network, and the compute service are
`Technology`. Archi stores that layer in Technology & Physical. The JSON keeps
the shorter name.

The types are the kebab-case ArchiMate names. What each one means is in the
[ArchiMate 3.2 Specification](https://pubs.opengroup.org/architecture/archimate32-doc/).
This file uses the Business, Application, Technology, Motivation, and Strategy
chapters, plus Location and Grouping from the generic concepts. It has no
junction and no Implementation element.

| id | type | name | layer |
|---|---|---|---|
| `customer` | `business-actor` | Customer | Business |
| `carrier` | `business-actor` | Carrier | Business |
| `sender` | `business-role` | Sender | Business |
| `parcel-service` | `business-service` | Parcel service | Business |
| `book` | `business-process` | Book parcel | Business |
| `sort` | `business-process` | Sort parcel | Business |
| `parcel-file` | `business-object` | Parcel file | Business |
| `portal` | `application-component` | Booking portal | Application |
| `core` | `application-component` | Sorting core | Application |
| `booking-api` | `application-interface` | Booking API | Application |
| `booking-service` | `application-service` | Booking service | Application |
| `parcel-record` | `data-object` | Parcel record | Application |
| `host` | `node` | Depot host | Technology |
| `runtime` | `system-software` | Parcel runtime | Technology |
| `scanner` | `device` | Scanner | Technology |
| `network` | `communication-network` | Depot network | Technology |
| `compute` | `technology-service` | Compute service | Technology |
| `director` | `stakeholder` | Operations director | Motivation |
| `speed` | `driver` | Delivery speed | Motivation |
| `next-day` | `goal` | Deliver next day | Motivation |
| `faster` | `outcome` | Faster delivery | Motivation |
| `scan-all` | `principle` | Scan every parcel | Motivation |
| `record-handover` | `requirement` | Record every handover | Motivation |
| `delivery` | `capability` | Parcel delivery | Strategy |
| `depot-staff` | `resource` | Depot staff | Strategy |
| `lockers` | `course-of-action` | Extend locker network | Strategy |
| `drop-off` | `value-stream` | Drop-off to doorstep | Strategy |
| `depot` | `location` | City depot | Other |
| `enterprise` | `grouping` | Parcel enterprise | Other |
| `motivation` | `grouping` | Motivation | Other |
| `strategy` | `grouping` | Strategy | Other |
| `business` | `grouping` | Business | Other |
| `applications` | `grouping` | Applications | Other |
| `platform` | `grouping` | Depot platform | Other |

The City depot is one element and it is nested twice. On the System context
view its parent is `enterprise`. On the Infrastructure view its parent is
`platform`. `parent` belongs to the view node, so the same element can sit in
a different box on a different view.

## Relationships

A relationship has `id`, `type`, `source`, and `target`. Four of them also
have `name`, which Archi draws on the line: `customer-role` is "plays",
`book-sort` is "booked", `portal-core` is "booking", and `service-book` is
"books".

Thirty relationships are drawn when both ends are on a view. The other 27 are
aggregations with `"draw": false`. Each one runs from a grouping to a member.
That is the membership record from the guide: the nested box is what the
reader sees, and the aggregation stays in the model without a line across the
box. The depot has two of these, one from `enterprise` and one from
`platform`, because it is a member of both groupings.

`sender-book` is a real assignment from the sender to Book parcel, and it is
drawn on no view. The sender is only on the System context view and Book
parcel is only on the Logical architecture view. The guide draws a line only
when both ends are placed on that view.

`host-runtime` is a composition from the Node to the System Software. That is
the legal direction on Archi 5.3. The claims file uses assignment for the same
pair of concepts. Both directions that the guide allows are node to system
software. Assignment from the runtime back to the host is rejected.

There is no junction, so the junction rule does not come up.

The drawn relationships, and the views that place both ends:

| id | type | source → target | Views |
|---|---|---|---|
| `customer-role` | assignment | customer → sender | System context |
| `service-sender` | serving | parcel-service → sender | System context |
| `carrier-depot` | association | carrier → depot | System context |
| `sender-book` | assignment | sender → book | none |
| `book-sort` | triggering | book → sort | Logical architecture |
| `book-file` | access | book → parcel-file | Logical architecture |
| `sort-file` | access | sort → parcel-file | Logical architecture |
| `portal-core` | flow | portal → core | Logical architecture |
| `portal-api` | composition | portal → booking-api | Logical architecture |
| `core-service` | realization | core → booking-service | Logical architecture |
| `service-book` | serving | booking-service → book | Logical architecture |
| `core-record` | access | core → parcel-record | Logical architecture |
| `director-speed` | association | director → speed | Conceptual architecture |
| `director-goal` | association | director → next-day | Conceptual architecture |
| `speed-goal` | influence | speed → next-day | Conceptual architecture |
| `speed-outcome` | influence | speed → faster | Conceptual architecture |
| `outcome-goal` | realization | faster → next-day | Conceptual architecture |
| `principle-goal` | realization | scan-all → next-day | Conceptual architecture |
| `principle-requirement` | influence | scan-all → record-handover | Conceptual architecture |
| `goal-requirement` | influence | next-day → record-handover | Conceptual architecture |
| `staff-capability` | assignment | depot-staff → delivery | Conceptual architecture |
| `lockers-capability` | serving | lockers → delivery | Conceptual architecture |
| `capability-goal` | realization | delivery → next-day | Conceptual architecture |
| `capability-stream` | serving | delivery → drop-off | Conceptual architecture |
| `depot-host` | association | depot → host | Infrastructure |
| `host-runtime` | composition | host → runtime | Infrastructure |
| `host-scanner` | composition | host → scanner | Infrastructure |
| `host-network` | association | host → network | Infrastructure |
| `runtime-compute` | realization | runtime → compute | Infrastructure |
| `compute-host` | serving | compute → host | Infrastructure |

## Views

Every view uses the viewpoint `layered` and the folder `Parcel`. `layered`
shows every concept, which is why one file can put motivation, strategy,
business, application, and technology on its diagrams. The documentation
string on each view is the sentence in the file.

A grouping node sets `w` and `h`. A member node sets `parent` to that grouping
and comes later in the `nodes` array. Member `x` and `y` are relative to the
grouping's top-left. Member width and height are omitted, so they stay 148 by
58. The System context view has no `routes` key. The other three views have a
`routes` array.

| View | Groupings | Members |
|---|---|---|
| Conceptual architecture | Motivation at (40, 40), 632 by 414. Strategy at (40, 534), 632 by 394. | 6 motivation concepts, 4 strategy concepts |
| System context | Parcel enterprise at (40, 200), 632 by 162. | Sender, parcel service, and the depot. The customer and the carrier stand outside the box. |
| Logical architecture | Business at (40, 40), 632 by 214. Applications at (40, 334), 632 by 362. | 3 business concepts, 5 application concepts |
| Infrastructure | Depot platform at (40, 40), 632 by 394. | The depot, the host, the scanner, the network, the runtime, and the compute service |

## Grid

The cell is the one in the guide. Inside a grouping:

```text
member x = 32 + column * 210
member y = 56 + row * 200
grouping width  = 32 * 2 + (columns - 1) * 210 + 148
grouping height = 56 + (rows - 1) * 200 + 58 + pad bottom
```

Every grouping in this file has 3 columns, so every width is
`64 + 2 * 210 + 148 = 632`. Columns line up from one grouping to the next
because every grouping starts at `x = 40`. The next grouping down starts at
`previous y + previous height + 80`.

Check the Motivation box. The highest row is 1, so there are 2 rows, and
`pad bottom` is 100 because lanes run under both rows:

```text
height = 56 + 1 * 200 + 58 + 100 = 414
```

That is the `h` on the motivation node. Strategy then starts at
`40 + 414 + 80 = 534`.

| Grouping | Rows | pad bottom | Height | Why the pad is that size |
|---|---|---|---|---|
| Motivation | 2 | 100 | 414 | The goal-requirement lane runs under the second row. |
| Strategy | 2 | 80 | 394 | The two strategy lanes sit in the gap between its rows. |
| Parcel enterprise | 1 | 48 | 162 | Nothing is routed under the row. 48 is the guide default. |
| Business | 1 | 100 | 214 | The book-file lane runs under the only row. |
| Applications | 2 | 48 | 362 | Nothing is routed under the second row. |
| Depot platform | 2 | 80 | 394 | The two infrastructure lanes sit in the gap between its rows. |

Applications starts at `40 + 214 + 80 = 334`. The Infrastructure view is a
separate diagram, so the depot platform starts again at (40, 40).

A member's position on the view is the grouping origin plus the relative
coordinate. Delivery speed is column 1, row 0 of Motivation:

```text
relative x = 32 + 1 * 210 = 242
relative y = 56
view x = 40 + 242 = 282
view y = 40 + 56 = 96
centre x = 282 + 74 = 356
```

That centre is what a route uses. Route points are view coordinates, not
parent-relative coordinates.

### Actors outside the context box

The customer and the carrier are not nested. Their `x` is the view `x` of the
concept they relate to, and their `y` is 40. The sender's view `x` is
`40 + 32 = 72`, and the customer is at `x = 72`. The depot's view `x` is
`40 + 452 = 492`, and the carrier is at `x = 492`. The enterprise box starts
at `y = 200`, below both actors. This is the outside-actor pattern in the
guide.

## Straight lines

A line stays straight when the two elements share a row or a column and no
other element sits between them. Those relationships are absent from `routes`.
Sharing a column still counts when the two boxes are in different groupings,
as long as both groupings start at the same `x` and both members use the same
column. The vertical then runs through the 80-pixel gap between the boxes.

| Relationship | Why it is straight |
|---|---|
| `customer-role` | The customer and the sender both have view x = 72. The gap from y = 98 to the enterprise top at y = 200 is empty. |
| `carrier-depot` | The carrier and the depot both have view x = 492. Same gap. |
| `service-sender` | Both are on the one row inside the enterprise, in neighbouring columns 1 and 0. |
| `director-speed` | Neighbouring columns on the motivation top row. |
| `director-goal` | Both are column 0, one row apart, inside Motivation. |
| `speed-outcome` | Neighbouring columns on the motivation top row. |
| `principle-goal` | Neighbouring columns on the motivation second row. |
| `principle-requirement` | Neighbouring columns on that same row. |
| `staff-capability` | Neighbouring columns on the strategy top row. |
| `capability-goal` | Parcel delivery and Deliver next day are both column 0. One is in Strategy and the other is in Motivation, and the gap between those groupings is empty on that column. |
| `book-sort` | Neighbouring columns on the business row. |
| `sort-file` | Neighbouring columns on the business row. |
| `portal-core` | Neighbouring columns on the application top row. |
| `portal-api` | The portal and the Booking API share column 2, one row apart. |
| `core-service` | Neighbouring columns on the application top row. |
| `service-book` | Booking service and Book parcel are both column 0. The line crosses the gap between the Applications box and the Business box. |
| `core-record` | The core and the parcel record share column 1, one row apart. |
| `depot-host` | Neighbouring columns on the platform top row. |
| `host-runtime` | The host and the runtime share column 1, one row apart. |
| `host-scanner` | Neighbouring columns on the platform top row. |
| `runtime-compute` | Neighbouring columns on the platform second row. |

## Lanes

A line that would pass through another element has two points on one
horizontal lane. The lane y for slot 0 is the bottom of the row plus 16. The
next slot is 22 pixels lower. When two lines would share the vertical into
one element, one of them moves 18 pixels off that centre.

The bottom of a nested row on the view is `grouping y + member y + 58`.

### Conceptual architecture

Five routes.

**`speed-goal`.** Delivery speed is column 1 of the top row and Deliver next
day is column 0 of the second row. A straight diagonal would cross the
director. The lane is slot 0 under the top row. The top row's view bottom is
`96 + 58 = 154`.

```text
lane y = 154 + 16 = 170
speed centre x = 356
next-day centre x = 146
points = (356, 170), (146, 170)
```

**`outcome-goal`.** Faster delivery is column 2 of the top row, and the goal
is column 0 of the second row. `director-goal` already uses the vertical at
the goal's centre, x = 146, and `speed-goal` already uses y = 170. This line
takes slot 2 and arrives 18 pixels to the left of the goal.

```text
lane y = 154 + 16 + 2 * 22 = 214
faster centre x = 566
target x = 146 - 18 = 128
points = (566, 214), (128, 214)
```

**`goal-requirement`.** Deliver next day and Record every handover are on the
second row, with Scan every parcel between them. The lane is slot 0 under
that row. The second row's view y is `40 + 256 = 296`, so its bottom is 354.

```text
lane y = 354 + 16 = 370
points = (146, 370), (566, 370)
```

**`lockers-capability`.** Extend locker network is column 1 of the strategy
second row. Parcel delivery is column 0 of the strategy top row. The lane is
slot 0 under that top row, which stays above the locker box. Strategy starts
at y = 534, so the top row's view y is 590 and its bottom is 648.

```text
lane y = 648 + 16 = 664
lockers centre x = 356
delivery centre x = 146
points = (356, 664), (146, 664)
```

The vertical from the lockers up to y = 664 stops 16 pixels under Depot
staff, so it does not enter that box.

**`capability-stream`.** Parcel delivery and Drop-off to doorstep have Depot
staff between them on the top row. The lane is the next slot under that row,
22 pixels below the locker lane.

```text
lane y = 664 + 22 = 686
points = (146, 686), (566, 686)
```

### Logical architecture

One route, **`book-file`.** Book parcel and the parcel file are on the same
row, with Sort parcel between them. Business starts at y = 40, the row's view
y is 96, and its bottom is 154.

```text
lane y = 154 + 16 = 170
book centre x = 146
parcel-file centre x = 566
points = (146, 170), (566, 170)
```

The line leaves Book parcel, crosses under the row at y = 170, and enters the
parcel file. It passes over Sort parcel. The extra pad on the Business box
keeps that lane inside the grouping.

### Infrastructure

Two routes, both in the gap under the platform's top row. The host's view y
is 96 and its bottom is 154.

**`host-network`.** The depot sits between the host and the network, so the
line cannot cut the corner. Slot 0 uses the two centres.

```text
lane y = 154 + 16 = 170
host centre x = 356
network centre x = 146
points = (356, 170), (146, 170)
```

**`compute-host`.** The compute service is column 2 of the second row and the
host is column 1 of the top row. `host-runtime` already uses the host's
centre column, x = 356. This line takes the next slot and shifts 18 pixels
off both centres, so it stays beside that column.

```text
lane y = 170 + 22 = 192
source x = 566 - 18 = 548
target x = 356 + 18 = 374
points = (548, 192), (374, 192)
```

## What the polyline check sees

Read each routed line as source centre, then the two points, then target
centre. `speed-goal` leaves (356, 125), drops to (356, 170), crosses to
(146, 170), and enters Deliver next day. That path stays under the top row
and beside the director. `service-book` has no points: both centres share
x = 146, and the segment between the two groupings crosses empty space.
`compute-host` enters the host at x = 374, eighteen pixels to the right of
the runtime column. A segment ends in its own element and does not pass
through any other box. A segment may cross the grouping that contains its
own element. That box is the area, not an obstacle.
