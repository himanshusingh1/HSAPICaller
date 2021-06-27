# HSAPICaller
HSAPICaller is a wrapper written upon Moya (ref: [Moya][moya_github] ) to make API Calls with ease, and make it cacheable without adding any extra lines of code.


## Features
- Use REST API Call as Operation for better controll. 
- Keep Code clean and Readable.
- Write API Calls fast and easy.
- In built cache keep tracks of what to cache and when to deliver data from server/cache.
- Cache is never stored in memory so it makes it memory (RAM) friendly.
- Use facilities like Operation Dependencies and others for better SOLID Code

## Sample Projects
 Please find the Demo Project on link : [DEMO PROJECT] [demo_project]

# Targets

Using HSAPICaller starts with defining a target – typically some `enum` that conforms
to the `HSTarget` protocol. Then, the rest of your app deals *only* with
those targets. Targets are some action that you want to take on the API,
like "`favoriteTweet(tweetID: String)`".

Here's an example:

```swift
public enum GitHub {
    case zen
    case userProfile(String)
    case userRepositories(String)
    case branches(String, Bool)
}
```

Targets must conform to `HSTarget`. The `HSTarget` protocol requires a
`baseURL` property to be defined on the enum. Note that this should *not* depend
on the value of `self`, but should just return a single value (if you're using
more than one API base URL, separate them out into separate enums and Moya
providers). Here's the beginning of our extension:

```swift
extension GitHub: HSTarget {
    public var baseURL: URL { return URL(string: "https://api.github.com")! }
}
```

This protocol specifies the locations of
your API endpoints, relative to its base URL (more on that below).

```swift
public var path: String {
    switch self {
    case .zen:
        return "/zen"
    case .userProfile(let name):
        return "/users/\(name.urlEscaped)"
    case .userRepositories(let name):
        return "/users/\(name.urlEscaped)/repos"
    case .branches(let repo, _):
        return "/repos/\(repo.urlEscaped)/branches"
    }
}
```

Notice that we're ignoring the second associated value of our `branches` Target using the Swift `_` ignored-value symbol. That's because we don't need it to define the `branches` path.
Note: we're cheating here and using a `urlEscaped` extension on String.
A sample implementation is given at the end of this document.

OK, cool. So now we need to have a `method` for our enum values. In our case, we
are always using the GET HTTP method, so this is pretty easy:

```swift
public var method: Moya.Method {
    return .get
}
```

Nice. If some of your endpoints require POST or another method, then you can switch
on `self` to return the appropriate value. This kind of switching technique is what
we saw when calculating our `path` property.

Our `TargetType` is shaping up, but we're not done yet. We also need a `task`
computed property that returns the task type potentially including parameters.
Here's an example:

```swift
public var task: Task {
    switch self {
    case .userRepositories:
        return .requestParameters(parameters: ["sort": "pushed"], encoding: URLEncoding.default)
    case .branches(_, let protected):
        return .requestParameters(parameters: ["protected": "\(protected)"], encoding: URLEncoding.default)
    default:
        return .requestPlain
    }
}
```

Unlike our `path` property earlier, we don't actually care about the associated values of our `userRepositories` case, so we just skip parenthesis.
Let's take a look at the `branches` case: we'll use our `Bool` associated value (`protected`) as a request parameter by assigning it to the `"protected"` key. We're parsing our `Bool` value to `String`. (Alamofire does not encode `Bool` parameters automatically, so we need to do it by our own).

While we are talking about parameters, we needed to indicate how we want our
parameters to be encoded into our request. We do this by returning a
`ParameterEncoding` alongside the `.requestParameters` task type. Out of the
box, Moya has `URLEncoding`, `JSONEncoding`, and `PropertyListEncoding`. You can
also create your own encoder that conforms to `ParameterEncoding` (e.g.
`XMLEncoder`).

A `task` property represents how you are sending / receiving data and allows you to add data, files and streams to the request body. There are several `.request` types:
- `.requestPlain` with nothing to send at all
- `.requestData(_:)` with which you can send `Data` 
- `.requestJSONEncodable(_:)` with which you can send objects that conform to the `Encodable` protocol
- `.requestCustomJSONEncodable(_:encoder:)`  which allows you to send objects conforming to `Encodable` encoded with provided custom JSONEncoder
- `.requestParameters(parameters:encoding:)` which allows you to send parameters with an encoding
- `.requestCompositeData(bodyData:urlParameters:)` & `.requestCompositeParameters(bodyParameters:bodyEncoding:urlParameters)` which allow you to combine url encoded parameters with another type (data / parameters)

Also, there are three upload types: 
- `.uploadFile(_:)` to upload a file from a URL, 
- `.uploadMultipart(_:)` for multipart uploads
- `.uploadCompositeMultipart(_:urlParameters:)` which allows you to pass multipart data and url parameters at once

And two download types: 
- `.downloadDestination(_:)` for a plain file download
- `.downloadParameters(parameters:encoding:destination:)` for downloading with parameters sent alongside the request.

Next, notice the `sampleData` property on the enum. This is a requirement of
the `TargetType` protocol. Any target you want to hit must provide some non-nil
`Data` that represents a sample response. This can be used later for tests or
for providing offline support for developers. This *should* depend on `self`.

```swift
public var sampleData: Data {
    switch self {
    case .zen:
        return "Half measures are as bad as nothing at all.".data(using: String.Encoding.utf8)!
    case .userProfile(let name):
        return "{\"login\": \"\(name)\", \"id\": 100}".data(using: String.Encoding.utf8)!
    case .userRepositories(let name):
        return "[{\"name\": \"Repo Name\"}]".data(using: String.Encoding.utf8)!
    case .branches:
        return "[{\"name\": \"master\"}]".data(using: String.Encoding.utf8)!
    }
}
```
Cache Policy
-------------

```swift
public var cachePolicy: HSCachePolicy {
    switch self {
    case .zen:
        return .never
    case .userProfile(let name):
        return .never
    case .userRepositories(let name):
        return firstFromCache(timeLimit: 120)
    case .branches:
        return refreshCache(timeLimit: 10)
    }
}
```

To Enable Caching in the api, all Targets should give defination of  `cachePolicy`,
which can have three values

- 1: `.never` which indicates that no need of caching
- 2: `firstFromCache(timeLimit: TimeInterval)` which indicates if data is present in cache it should return from cache only and no need of internet is required, `timeLimit` denotes the expiry of cache , example: .firstFromCache(timeLimit: 120) means, system will try to get data from cache first and if it is not present REST Call will be made, and new data will be cached for next 120 seconds, after which it will be automatically removed.
- 3: `refreshCache(timeLimit: TimeInterval)` which indicates no matter what data should be fetched from REST and new data should be cached for the given timeLimit

Finally, the `headers` property stores header fields that should be sent on the request.

```swift
public var headers: [String: String]? {
    return ["Content-Type": "application/json"]
}
```

After this setup, creating our [Provider](Providers.md) is as easy as the following:

```swift
let GitHubProvider = MoyaProvider<GitHub>()
```

Escaping URLs
-------------

Here's an example extension that allows you to easily escape normal strings
"like this" to URL-encoded strings "like%20this":

```swift
extension String {
    var urlEscaped: String {
        return addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
    }
}
```




## Installation Using Swift Package Manager
To integrate using Apple's Swift package manager, without Xcode integration, add the following as a dependency to your Package.swift:
```sh
.package(url: "https://github.com/himanshusingh1/HSAPICaller.git", .upToNextMajor(from: "1.0.5"))
```

## License

MIT

[//]: # (These are reference links used in the body of this note and get stripped out when the markdown processor does its job. There is no need to format nicely because it shouldn't be seen. Thanks SO - http://stackoverflow.com/questions/4823468/store-comments-in-markdown-syntax)
   [demo_project]: <https://github.com/himanshusingh1/HSAPICaller/tree/main/Demo_project>
   [moya_github]: <https://github.com/Moya>
  

