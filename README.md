# system-landscape

Three self-contained pages — no build step, no server, no side files.
Open any of them straight from disk (`file://` works):

| file | style |
|---|---|
| `landscape.html` | the original look, follows the OS light/dark setting |
| `landscape-blueprint.html` | dark drafting paper: grid, monospace, hard edges, glowing wires |
| `landscape-editorial.html` | warm paper: serif headings, roomy layout, calm wires |
| `landscape-example.html` | same page as the first, carrying the showcase model below |

All four carry the same behaviour; the first three carry the same small model. Each is ~105 KB, of which
62 KB is [js-yaml](https://github.com/nodeca/js-yaml) (MIT), inlined so the page
can parse YAML without a server.

## The model

The whole model is the YAML inside the `<script type="application/yaml" id="model-data">`
block near the bottom of each file. Edit it there and reload the page; a syntax error is
reported in the page, with line and column, instead of leaving a blank canvas. Comments
are allowed, keys starting with `_` are ignored, and the `_reference` block at the top
documents every field.

Every field of this model is text, so the YAML is read with js-yaml's failsafe schema:
no value is ever turned into a number or a boolean. `firmware: 1.20` stays `"1.20"`,
`serial: 0012345` keeps its leading zero, and `notes: no` stays the word `no`. Quoting
is therefore optional, never load-bearing.

**Download YAML** hands out what the page currently shows, byte for byte.
**Download JSON** writes the same model as JSON, if something else needs to read it.

## Clusters, workloads and interfaces

An element becomes a cluster by carrying a `cluster:` block — free key/value facts such as
distribution, version, CNI or CIDRs. Its node chips are then **grouped and counted by
`role`** (control plane · 3, worker · 4, storage · 2) instead of listed flat, and the facts
show up in the panel.

A cluster can also list `workloads:` — `namespace`, `name`, `kind` (Deployment, StatefulSet,
DaemonSet, CronJob …), `replicas`, `image`, `ports`, `notes`. They render as a second row of
chips inside the element, each one selectable with its own panel, and a link can point
straight at one:

```yaml
links:
  - from: fra-lb
    to: k8s-fra
    toWorkload: ops/ingress-nginx     # id, namespace/name, or bare name
    type: app
    ports: 443/tcp
```

A node that sits in several networks lists them under `interfaces:` — `name`, `network`,
`ip`, `vlan`, `mac`, `mtu`, `notes`, plus any extra key, which becomes an extra column. The
`network` may be a zone id, in which case the panel shows that zone's name. The panel prints
one row per interface, and a link can name the NIC it runs over:

```yaml
nodes:
  - name: w-1
    role: worker
    interfaces:
      - name: eno1
        network: fra-net       # zone id -> shown as "Core Network"
        ip: 10.10.0.41/24
        vlan: "10"
      - name: ens3f0
        network: fra-stor
        ip: 10.10.40.41/24
        mtu: "9000"
        notes: Storage traffic only, no default route

links:
  - from: k8s-fra
    fromNode: w-1
    fromIface: ens3f0
    to: fra-san
    type: l2
    direction: bi
```

The single `ip:` field on a node still works for the simple case. Wires end on the exact
chip — node or workload — that a link names, including between two chips of the same
element.

## Services outside your sites

`edge:` and `shared:` are drawn as full-width bands above the sites. `outside:` takes the same
list of zones and draws it as a band **below** the sites. It's meant for services you use but
don't run, like SaaS, payment providers or a public CA. The zone type `external` gives them
their own neutral colour. Links to and from them work like any other link.

```yaml
outside:
  - id: z-saas
    name: External Services
    type: external
    items:
      - id: ext-psp
        name: Card Processor
        kind: saas
```

## External systems (deep links)

List the tools your team works in (IPAM, DNS, monitoring, CMDB, config backup) once, under a
top-level `systems:` key. The panel then shows an **Open in** row of links. Each `url` is a
template: `{field}` is filled from the selected object first, then from its parents
(interface → node → item → zone).

```yaml
systems:
  - id: ipam
    name: NetBox IPAM
    home: https://netbox.corp.example/            # optional, listed in the overview
    url: https://netbox.corp.example/ipam/ip-addresses/?q={ip|addr}
    on: [node, interface]                         # appears there by itself
  - id: dns
    name: DNS records
    url: https://dns.corp.example/zones/{zone}/records?name={record}   # no on: only where named
```

- `{node.name}`, `{item.id}` or `{item.cluster.Version}` read from one level only. `{ip|addr}`
  removes a `/24`-style prefix.
- Every value is URL-encoded. A link with a placeholder that has no value is hidden, so you never
  get a half-filled URL.
- Only `http(s)` URLs are shown. Links open in a new tab.

Any item, node, workload or interface can add its own links under `external:`. Each entry can be:

- a system id (on its own, or as a list), or
- `{system: dns, zone: corp.example, record: api}`, which supplies or overrides the fields the
  template needs, or
- `{label: Runbook, url: https://wiki.corp.example/{namespace}-{name}}` for a one-off link.

On an interface, the links appear on a line under its row in the interface table.

## Edit mode

**Edit model** opens the YAML in a box above the diagram. It is applied automatically
about 400 ms after you stop typing: the diagram, the legend and the wires redraw, and
the selected element stays selected if it survived the edit. Invalid YAML leaves the
last good diagram on screen and reports where the parser stopped. **Reformat**
re-dumps the document through the YAML dumper (2-space indent — note that this drops
comments), **Revert** goes back to the YAML embedded in the file.

Edits live in the tab only — nothing is written back to disk. Keep them with
**Download YAML**, or paste the text into the `<script id="model-data">` block.

## The example

`landscape-example.html` is a worked model — two sites, shared services, an edge and
external services, 20 elements, 27 nodes, 29 connections — that uses **every field the page understands**
at least once, and carries no `_reference` block: the model itself is the documentation.
Open it to see what is possible, copy the parts you need.

What it demonstrates: all nine zone types, zone `tag` and a zone `color` override, item
`kind` / `subtitle` / `color` / `details`, nodes written both as plain names and as
objects, every documented node field plus a free-form extra key, all seven link types,
`uni` and `bi` direction, `ports` and `label`, links attached to a single node via
`fromNode` / `toNode`, and a link between two nodes of the same element.
It also uses `systems:` with and without `on:`, `home:`, `{item.id}`-style and `{ip|addr}`
placeholders, and every form of `external:` (a bare id, a system with its fields filled in, and
a one-off `label`/`url`).

It also carries a nine-node Kubernetes cluster — three control plane, four worker, two
storage — whose nodes have two to four interfaces each across the core, platform, storage
and out-of-band networks, and four workloads that links point at directly.

## Offline

Everything runs offline: no network calls, no external scripts, stylesheets or fonts.
Verified by rendering with DNS pointed at `0.0.0.0` and a dead proxy — the page draws
in full. Apart from the links you configure under `systems:` and `external:`, which open only when
clicked, the only URLs in the files are SVG namespace identifiers. Those are never fetched.

## Connections

Click an element (or a single node chip) to see what it talks to. **Animate** sends
travelling dashes along each connection, towards the target and back again for
bidirectional links; **Draw connections** turns the wires off entirely. Animation
starts switched off when the OS asks for reduced motion.
