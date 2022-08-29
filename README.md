# EVPN interoperability between SR Linux and SROS
Ethernet VPN proposes a unified model for VPNs and cloud-based services, by providing a control plane framework that can deliver any type of VPN services. SR Linux and SROS, network operating systems developed by Nokia, implement this protocol. This lab provides an interoperability use case between those two systems, in a data center context.  

A Clos fabric, traditional architecture for data centers, will be deployed, as represented below. It includes a fabric made of SR Linux routers, along with two 7750 SR-1 routers acting as Data Center Gateways.

## Deploying the lab
The lab is deployed with [containerlab](https://containerlab.dev) project where [`nokia-evpn.clab.yml`](nokia-evpn.clab.yml) file declaratively describes the lab topology.

```bash
# deploy the lab
containerlab deploy 
```

Once the lab is completed, it can be removed with the destroy command.

```bash
# destroy the lab
containerlab destroy 
```

## Accessing the network elements
After deploying the lab, the nodes will be accessible. To access a network element, simply use its hostname as described in the table displayed after execution of the deploy command.
```
ssh admin@clab-evpn-leaf1
ssh admin@clab-evpn-dcgw1
```
The Linux CE clients don't have SSH enabled. In order to access them, use `docker exec`.
```
docker exec -it clab-evpn-client1 bash
```

## Configuration
All nodes come preconfigured thanks to startup-config setting in the topology file [`nokia-evpn.clab.yml`](nokia-evpn.clab.yml). Those configuration files can be found in [`configs`](/configs). 

### Underlay
iBGP is used to provide underlay connectivity between the routers. The routes exchanged over those BGP sessions can be seen by executing the commands below.

#### Leaf 1 (SR Linux)
<pre>
A:leaf1# show network-instance default protocols bgp routes ipv4 summary
----------------------------------------------------------------------------------------
Show report for the BGP route table of network-instance "default"
----------------------------------------------------------------------------------------
Status codes: u=used, *=valid, >=best, x=stale
Origin codes: i=IGP, e=EGP, ?=incomplete
----------------------------------------------------------------------------------------
+-----+--------------+--------------------+-----+-----+--------------------------------+
| Sta |   Network    |      Next Hop      | MED | Loc |            Path Val            |
| tus |              |                    |     | Pre |                                |
|     |              |                    |     |  f  |                                |
+=====+==============+====================+=====+=====+================================+
| u*> | 10.0.0.11/32 | 0.0.0.0            | -   | 100 |  i                             |
| u*> | 10.0.0.12/32 | 100.21.11.1        | -   | 100 | [65020, 65012] i               |
| *   | 10.0.0.12/32 | 100.22.11.1        | -   | 100 | [65020, 65012] i               |
| u*> | 10.0.0.13/32 | 100.21.11.1        | -   | 100 | [65020, 65013] i               |
| *   | 10.0.0.13/32 | 100.22.11.1        | -   | 100 | [65020, 65013] i               |
| u*> | 10.0.0.14/32 | 100.21.11.1        | -   | 100 | [65020, 65014] i               |
| *   | 10.0.0.14/32 | 100.22.11.1        | -   | 100 | [65020, 65014] i               |
| u*> | 10.0.0.21/32 | 100.21.11.1        | -   | 100 | [65020] i                      |
| u*> | 10.0.0.22/32 | 100.22.11.1        | -   | 100 | [65020] i                      |
| u*> | 10.0.0.31/32 | 100.21.11.1        | -   | 100 | [65020, 65030] i               |
| *   | 10.0.0.31/32 | 100.22.11.1        | -   | 100 | [65020, 65030] i               |
| u*> | 10.0.0.32/32 | 100.21.11.1        | -   | 100 | [65020, 65030] i               |
| *   | 10.0.0.32/32 | 100.22.11.1        | -   | 100 | [65020, 65030] i               |
| u*> | 100.21.11.0/ | 0.0.0.0            | -   | 100 |  i                             |
|     | 30           |                    |     |     |                                |
| u*> | 100.22.11.0/ | 0.0.0.0            | -   | 100 |  i                             |
|     | 30           |                    |     |     |                                |
+-----+--------------+--------------------+-----+-----+--------------------------------+
----------------------------------------------------------------------------------------
15 received BGP routes: 10 used, 15 valid, 0 stale
10 available destinations: 5 with ECMP multipaths
----------------------------------------------------------------------------------------
</pre>

#### DCGW 1 (SROS)
<pre>
A:admin@dcgw1# show router bgp routes ipv4 brief
===============================================================================
 BGP Router ID:10.0.0.31        AS:65030       Local AS:65030
===============================================================================
 Legend -
 Status codes  : u - used, s - suppressed, h - history, d - decayed, * - valid
                 l - leaked, x - stale, > - best, b - backup, p - purge
 Origin codes  : i - IGP, e - EGP, ? - incomplete

===============================================================================
BGP IPv4 Routes
===============================================================================
Flag  Network
-------------------------------------------------------------------------------
u*>i  10.0.0.11/32
*i    10.0.0.11/32
u*>i  10.0.0.12/32
*i    10.0.0.12/32
u*>i  10.0.0.13/32
*i    10.0.0.13/32
u*>i  10.0.0.14/32
*i    10.0.0.14/32
u*>i  10.0.0.21/32
u*>i  10.0.0.22/32
i     10.0.0.32/32
i     10.0.0.32/32
-------------------------------------------------------------------------------
Routes : 12
===============================================================================
</pre>


### Overlay
MP-BGP is used to provide overlay connectivity between the routers, and to therefore exchange EVPN routes. A Layer-2 service is defined on the leafs, it gives access to a multi-homed node. Multi-homing with EVPN requires the advertisement of Ethernet Auto-Discovery routes between leafs and up to the DCGWs. Those routes can be seen with the commands provided below.

#### Leaf 1 (SR Linux)
<pre>
A:leaf1# /show network-instance default protocols bgp routes evpn route-type 1 summary
--------------------------------------------------------------------------------------------------------
Show report for the BGP route table of network-instance "default"
--------------------------------------------------------------------------------------------------------
Status codes: u=used, *=valid, >=best, x=stale
Origin codes: i=IGP, e=EGP, ?=incomplete
--------------------------------------------------------------------------------------------------------
BGP Router ID: 10.0.0.11      AS: 65011      Local AS: 65011
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
Type 1 Ethernet Auto-Discovery Routes
+--------+-----------+--------------------------------+------------+-----------+-----------+-----------+
| Status | Route-dis |              ESI               |   Tag-ID   | neighbor  | Next-hop  |    VNI    |
|        | tinguishe |                                |            |           |           |           |
|        |     r     |                                |            |           |           |           |
+========+===========+================================+============+===========+===========+===========+
| u*>    | 1:12      | 01:01:01:01:01:01:01:01:01:01  | 0          | 10.0.0.21 | 10.0.0.12 | 1         |
| *      | 1:12      | 01:01:01:01:01:01:01:01:01:01  | 0          | 10.0.0.22 | 10.0.0.12 | 1         |
| u*>    | 1:12      | 01:01:01:01:01:01:01:01:01:01  | 4294967295 | 10.0.0.21 | 10.0.0.12 | -         |
| *      | 1:12      | 01:01:01:01:01:01:01:01:01:01  | 4294967295 | 10.0.0.22 | 10.0.0.12 | -         |
| u*>    | 1:13      | 02:02:02:02:02:02:02:02:02:02  | 0          | 10.0.0.21 | 10.0.0.13 | 1         |
| *      | 1:13      | 02:02:02:02:02:02:02:02:02:02  | 0          | 10.0.0.22 | 10.0.0.13 | 1         |
| u*>    | 1:13      | 02:02:02:02:02:02:02:02:02:02  | 4294967295 | 10.0.0.21 | 10.0.0.13 | -         |
| *      | 1:13      | 02:02:02:02:02:02:02:02:02:02  | 4294967295 | 10.0.0.22 | 10.0.0.13 | -         |
| u*>    | 1:14      | 02:02:02:02:02:02:02:02:02:02  | 0          | 10.0.0.21 | 10.0.0.14 | 1         |
| *      | 1:14      | 02:02:02:02:02:02:02:02:02:02  | 0          | 10.0.0.22 | 10.0.0.14 | 1         |
| u*>    | 1:14      | 02:02:02:02:02:02:02:02:02:02  | 4294967295 | 10.0.0.21 | 10.0.0.14 | -         |
| *      | 1:14      | 02:02:02:02:02:02:02:02:02:02  | 4294967295 | 10.0.0.22 | 10.0.0.14 | -         |
+--------+-----------+--------------------------------+------------+-----------+-----------+-----------+
12 Ethernet Auto-Discovery routes 6 used, 12 valid
--------------------------------------------------------------------------------------------------------
</pre>

#### DCGW 1 (SROS)
<pre>
A:admin@dcgw1# show router bgp routes evpn auto-disc
===============================================================================
 BGP Router ID:10.0.0.31        AS:65030       Local AS:65030
===============================================================================
 Legend -
 Status codes  : u - used, s - suppressed, h - history, d - decayed, * - valid
                 l - leaked, x - stale, > - best, b - backup, p - purge
 Origin codes  : i - IGP, e - EGP, ? - incomplete

===============================================================================
BGP EVPN Auto-Disc Routes
===============================================================================
Flag  Route Dist.         ESI                           NextHop
      Tag                                               Label
-------------------------------------------------------------------------------
u*>i  1:11                01:01:01:01:01:01:01:01:01:01 10.0.0.11
      0                                                 VNI 1

*i    1:11                01:01:01:01:01:01:01:01:01:01 10.0.0.11
      0                                                 VNI 1

u*>i  1:11                01:01:01:01:01:01:01:01:01:01 10.0.0.11
      MAX-ET                                            VNI 0

*i    1:11                01:01:01:01:01:01:01:01:01:01 10.0.0.11
      MAX-ET                                            VNI 0

u*>i  1:12                01:01:01:01:01:01:01:01:01:01 10.0.0.12
      0                                                 VNI 1

*i    1:12                01:01:01:01:01:01:01:01:01:01 10.0.0.12
      0                                                 VNI 1

u*>i  1:12                01:01:01:01:01:01:01:01:01:01 10.0.0.12
      MAX-ET                                            VNI 0

*i    1:12                01:01:01:01:01:01:01:01:01:01 10.0.0.12
      MAX-ET                                            VNI 0

u*>i  1:13                02:02:02:02:02:02:02:02:02:02 10.0.0.13
      0                                                 VNI 1

*i    1:13                02:02:02:02:02:02:02:02:02:02 10.0.0.13
      0                                                 VNI 1

u*>i  1:13                02:02:02:02:02:02:02:02:02:02 10.0.0.13
      MAX-ET                                            VNI 0

*i    1:13                02:02:02:02:02:02:02:02:02:02 10.0.0.13
      MAX-ET                                            VNI 0

u*>i  1:14                02:02:02:02:02:02:02:02:02:02 10.0.0.14
      0                                                 VNI 1

*i    1:14                02:02:02:02:02:02:02:02:02:02 10.0.0.14
      0                                                 VNI 1

u*>i  1:14                02:02:02:02:02:02:02:02:02:02 10.0.0.14
      MAX-ET                                            VNI 0

*i    1:14                02:02:02:02:02:02:02:02:02:02 10.0.0.14
      MAX-ET                                            VNI 0

-------------------------------------------------------------------------------
Routes : 16
===============================================================================
</pre>


### Advertising a MAC-IP route in the fabric
Since we have two clients connected behind the leafs, and a routed interface on both DCGWs, we can use those to send traffic between them. This will therefore create an EVPN MAC-IP route containing the MAC address of both clients. Note that MAC-IP entries are already advertised for the DCGW's routed interface : this is expected since those interfaces are statically defined. To send traffic from one of the client, connect to one of those and execute the following command.

```bash
ping 192.168.1.31
```

After execution, the MAC address of the client should be displayed, along with the Ethernet Segment Identifier.

<pre>
A:admin@dcgw1# show router bgp routes evpn mac
===============================================================================
 BGP Router ID:10.0.0.31        AS:65030       Local AS:65030
===============================================================================
 Legend -
 Status codes  : u - used, s - suppressed, h - history, d - decayed, * - valid
                 l - leaked, x - stale, > - best, b - backup, p - purge
 Origin codes  : i - IGP, e - EGP, ? - incomplete

===============================================================================
BGP EVPN MAC Routes
===============================================================================
Flag  Route Dist.         MacAddr           ESI
      Tag                 Mac Mobility      Label1
                          Ip Address
                          NextHop
-------------------------------------------------------------------------------
u*>i  1:11                aa:c1:ab:8b:7b:c9 01:01:01:01:01:01:01:01:01:01
      0                   Seq:0             VNI 1
                          n/a
                          10.0.0.11

*i    1:11                aa:c1:ab:8b:7b:c9 01:01:01:01:01:01:01:01:01:01
      0                   Seq:0             VNI 1
                          n/a
                          10.0.0.11

u*>i  1:12                aa:c1:ab:8b:7b:c9 01:01:01:01:01:01:01:01:01:01
      0                   Seq:0             VNI 1
                          n/a
                          10.0.0.12

*i    1:12                aa:c1:ab:8b:7b:c9 01:01:01:01:01:01:01:01:01:01
      0                   Seq:0             VNI 1
                          n/a
                          10.0.0.12

u*>i  1:32                52:54:00:6a:23:3e ESI-0
      0                   Static            VNI 1
                          192.168.1.32
                          10.0.0.32

*i    1:32                52:54:00:6a:23:3e ESI-0
      0                   Static            VNI 1
                          192.168.1.32
                          10.0.0.32

-------------------------------------------------------------------------------
Routes : 6
===============================================================================
</pre>