import Vapor
import Crypto
import FluentSQL
import SwiftGD
import Foundation

struct ImageController: APIRouteCollection {
	// Important that this stays a constant; changing after creation is not thread-safe.
	// Also, since this is based on DirectdoryConfiguration, the value is process-wide, not Application-wide.
	let imagesDirectory: URL
	
	// TODO: Currently this creates an images directory inside of `DerivedData`, meaning all images are deleted
	// on "Clean Build Folder". This doesn't reset the database, so you end up with a DB referencing images that aren't there.
	// It would be better to put images elsewhere and tie their lifecycle to the database.
	init() {
		let dir = DirectoryConfiguration.detect().workingDirectory
		imagesDirectory = URL(fileURLWithPath: dir).appendingPathComponent("images")
	}
 
    /// Required. Registers routes to the incoming router.
    func registerRoutes(_ app: Application) throws {
        
		// convenience route group for all /api/v3/image endpoints
		let imageRoutes = app.grouped("api", "v3", "image")

		// open access endpoints
		imageRoutes.get("full", ":image_filename", use: getImage_FullHandler)
		imageRoutes.get("thumb", ":image_filename", use: getImage_ThumbnailHandler)
	}
	
	func getImage_FullHandler(_ req: Request) throws -> Response {
		return try getImageHandler(req, typeStr: "full")
	}
	
	func getImage_ThumbnailHandler(_ req: Request) throws -> Response {
		return try getImageHandler(req, typeStr: "thumb")
	}
	
	func getImageHandler(_ req: Request, typeStr: String) throws -> Response {
		guard let fileParam = req.parameters.get("image_filename") else {
			throw Abort(.badRequest, reason: "No image file specified.")
		}
		
		// Check the extension
		var fileExtension = URL(fileURLWithPath: fileParam).pathExtension
		if ![".bmp", "gif", "jpg", "png", "tiff", "wbmp", "webp"].contains(fileExtension) {
			fileExtension = "jpg"
		}
		
		// Strip extension and any other gunk off the filename. Eject if two extensions detected (.php.jpg, for example).
		let noFiletype = URL(fileURLWithPath: fileParam).deletingPathExtension()
		if noFiletype.pathExtension.count > 0 {
			throw Abort(.badRequest, reason: "Malformed image filename.")
		}
		let filename = noFiletype.lastPathComponent
		// This check is important for security. Not only does it do the obvious, it protects
		// against "../../../../file_important_to_Swiftarr_operation" attacks.
		guard let fileUUID = UUID(filename) else {
			throw Abort(.badRequest, reason: "Image filename is not a valid UUID.")
		}
				
		// I don't think ~10K files in each directory is going to cause slowdowns, but if it does,
		// this will give us 128 subdirs.
		let subDirName = String(fileParam.prefix(2))
			
        let fileURL = imagesDirectory.appendingPathComponent(typeStr)
        		.appendingPathComponent(subDirName)
        		.appendingPathComponent(fileUUID.uuidString + "." + fileExtension)
		return req.fileio.streamFile(at: fileURL.path)
	}
}
