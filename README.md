FlamingoModel
=============

FlamingoModel models line based public transport networks. It is specifically designed to connect an abstract
mental map (implemented as a network of services) to real live operation. It consists of the following functional units:

    * Service Model
    * Journey Model
    * Infra Model
    * Sync Model


### Service Model

A **Service** is a collection of vehicle movements that run on the same public transport line.
Services are connected to the infrastructure through **ServicePoints**. ServicePoints contain default values for arrival, departure and platform,
thus allowing calculations (such as route-finding) without knowledge of an actual timetable.

A **Mission** is one vehicle movement, running on a specific date and time.
Missions are connected to Stations through **Stops**. Stops can contain planned arrival and departure times,
but more importantly, they also contain estimates of actual arrival and departure times.
A Mission can be cancelled and stops within a Mission can be rearranged due to re-routing.

A **Rule** defines which Missions should run, which is typically a daily or weekly recurring event.

Due to specificalities in the Dutch railway network a distinction was made between Services and **Series**.
Series and Services are similar in that they both represent a collection of vehicle movements, and ideally they are the same.
A Service is essentially a passenger-facing unit,
while a series is an operations-facing unit corresponding to 'trainseries' as used by the railway companies.
Distinction between Service and Series allows FlamingoModel to make a dedicated choice for passenger-facing Services
while still using Series to import timetable information.
series is also used to implement railway oriented business logic.


### Journey Model

A **Journey** models the movement of a passenger through the system.
Essentially a Journey is a chain of locations (modeled as **Visits**) linked by **TravelSections**.
If a TravelSection is travelled in a public transport vehicle, it is called a **Trajectory**.
A Trajectory links to one selected Mission and a set of alternative Missions.


### Infra Model

Infra Model enables the projection of public transport services into geographical space. Its main component is the **Route**.
Routes model physical infrastructure, they contain a *'heartline'* that indicates the geographical position of the infrastructure.
Routes can be connected to each other with **Junctions**, and it contains **Stations**, where passengers can alight or board.
Routes contain one or more **SubRoutes**, SubRoutes define the characteristics of the infrastructure, such as allowed speed or number of tracks.


### Sync Model

Sync Model contains a number of classes and methods to synchronize with an external service through a REST interface.


Programming platform
--------------------

FlamingoModel is written in Objective-C, on top of Core Data. It can be used in both OS-X and iOS projects.


In the repository
-----------------

The git repository contains:

    * The Core Data model
    * A series of objective-C model and controller classes
    * A series of testcases
    * An Xcode project file

FlamingoModel does not include a user interface. To inspect the data, use FlamingoEditor.


Compiling from source
---------------------

Create a location where you want to host your files.
```mkdir firstflamingo; cd firstflamingo```

Checkout this repository:
```git clone https://github.com/firstflamingo/FlamingoModel```

You can now open FlamingoEditor.xcodeproj in Xcode, and run the tests to see if everything is working properly.

