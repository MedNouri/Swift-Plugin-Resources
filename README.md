# Swift-Plugin-Resources
A swift package plugin that automatically generates Swift code for package asset resources


# How to use 


Package.swift based SPM project
Add a dependency in Package.swift:
```swift
dependencies: [
    .package(url: "https://github.com/MedNouri/Swift-Plugin-Resources", branch: "main")
]

```
For the related target, Add

```swift
 .target(
    name: "FeatureDemo",
    plugins: [
       .plugin(name: "AssetResources", package: "SwiftPluginResources")
     ]
   )
```


<img width="245" alt="Screenshot 2023-02-19 at 18 03 10" src="https://user-images.githubusercontent.com/17935370/219962978-7126b4c5-5ecd-4f28-9fc7-18dbf1eece2f.png">
