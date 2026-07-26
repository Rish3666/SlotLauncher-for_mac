import Cocoa

func bundleIdentifierForApp(at url: URL) -> String {
    if let bundle = Bundle(url: url), let id = bundle.bundleIdentifier, !id.isEmpty {
        return id
    }
    let plist = url.appendingPathComponent("Contents/Info.plist")
    guard let data = try? Data(contentsOf: plist),
          let dict = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
          let id = dict["CFBundleIdentifier"] as? String, !id.isEmpty else {
        return ""
    }
    return id
}

func appDisplayName(at url: URL) -> String {
    if let bundle = Bundle(url: url), let name = bundle.infoDictionary?["CFBundleName"] as? String {
        return name
    }
    let plist = url.appendingPathComponent("Contents/Info.plist")
    if let data = try? Data(contentsOf: plist),
       let dict = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
       let name = dict["CFBundleName"] as? String {
        return name
    }
    return url.deletingPathExtension().lastPathComponent
}
