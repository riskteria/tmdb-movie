// Coordinators own navigation. Scenes never push or present; their routers call closures a
// coordinator passed in through the scene factory.
protocol Coordinator: AnyObject {
    func start()
}
