# theo-example

Example project demonstrating how to use [Theo](https://github.com/Neo4j-Swift/Neo4j-Swift), the Neo4j Swift driver.

## Requirements

* macOS 14+ / iOS 17+ / Linux
* Swift 6.0+
* Neo4j 3.5+ with Bolt protocol enabled (port 7687)

## Command-Line Example

The `Sources/` directory contains a simple command-line example that demonstrates:
- Connecting to Neo4j using the Bolt protocol
- Creating nodes
- Fetching nodes by ID
- Running Cypher queries

### Build & Run

```bash
swift build
swift run theo-example
```

Make sure you have a Neo4j instance running on localhost:7687 with credentials neo4j/neo4j, or modify the connection settings in `Sources/main.swift`.

## iOS Example

The `theo-example/` directory contains an iOS app example with a UI for:
- Configuring connection settings
- Creating nodes
- Fetching nodes
- Running Cypher queries
- Executing transactions

### Setup

Open the project in Xcode and add the Theo package dependency:

1. File > Add Package Dependencies
2. Enter: `https://github.com/Neo4j-Swift/Neo4j-Swift.git`
3. Select version 6.0.0 or later

Then build and run on the iOS Simulator or device.

## Code Examples

### Connecting to Neo4j

```swift
import Theo

let client = try BoltClient(
    hostname: "localhost",
    port: 7687,
    username: "neo4j",
    password: "your-password",
    encrypted: true
)

let result = client.connectSync()
switch result {
case .failure(let error):
    print("Connection failed: \(error)")
case .success:
    print("Connected!")
}
```

### Creating a Node

```swift
let node = Node(label: "Person", properties: [
    "name": "Thomas Anderson",
    "alias": "Neo"
])

let result = client.createAndReturnNodeSync(node: node)
switch result {
case .failure(let error):
    print("Failed: \(error)")
case .success(let createdNode):
    print("Created node with ID: \(createdNode.id ?? 0)")
}
```

### Fetching a Node

```swift
client.nodeBy(id: 42) { result in
    switch result {
    case .failure(let error):
        print("Error: \(error)")
    case .success(let node):
        if let node = node {
            print("Found: \(node.properties)")
        }
    }
}
```

### Running Cypher Queries

```swift
let result = client.executeCypherSync(
    "MATCH (n:Person) WHERE n.name = $name RETURN n",
    params: ["name": "Thomas Anderson"]
)

switch result {
case .failure(let error):
    print("Query failed: \(error)")
case .success(let queryResult):
    for row in queryResult.rows {
        print(row)
    }
}
```

### Using Transactions

```swift
try client.executeAsTransaction { tx in
    client.executeCypherSync("CREATE (n:Test {prop: 'value1'})")
    client.executeCypherSync("CREATE (n:Test {prop: 'value2'})")

    // Call tx.markAsFailed() to rollback
}
```

## License

MIT License - see LICENSE file for details.
