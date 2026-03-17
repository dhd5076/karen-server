import Fluent
import Vapor

func routes(_ app: Application) throws {
    let locationController = LocationController()
    app.post("location", use : locationController.create)
}
