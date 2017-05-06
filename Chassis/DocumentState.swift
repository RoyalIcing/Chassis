//
//  DocumentState.swift
//  Chassis
//
//  Created by Patrick Smith on 8/03/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation
import Grain
import Freddy


enum EditedElement {
	case stage(sectionUUID: UUID, stageUUID: UUID)
	
	//case graphicComponent(NSUUID)
}

extension EditedElement : JSONRepresentable {
	init(json: JSON) throws {
		self = try json.decodeChoices(
	  { try .stage(sectionUUID: $0.decodeUUID("sectionUUID"), stageUUID: $0.decodeUUID("stageUUID")) }
		)
	}
	
	func toJSON() -> JSON {
		switch self {
		case let .stage(sectionUUID, stageUUID):
			return .dictionary([
				"sectionUUID": sectionUUID.toJSON(),
				"stageUUID": stageUUID.toJSON(),
			])
		}
	}
}


struct DocumentVersion {
	var version: Int
	var revision: Int = 0
}

extension DocumentVersion : JSONRepresentable {
	init(json: JSON) throws {
		try self.init(
			version: json.decode(at: "version"),
			revision: json.decode(at: "revision")
		)
	}
	
	func toJSON() -> JSON {
		return .dictionary([
			"version": version.toJSON(),
			"revision": revision.toJSON()
		])
	}
}


struct DocumentState {
	var version: DocumentVersion!
	var work: Work!
	var editedElement: EditedElement?
	var stageEditingMode: StageEditingMode = .visuals
	
	var shapeStyleUUIDForCreating: UUID?
}

extension DocumentState: JSONRepresentable {
	init(json: JSON) throws {
		try self.init(
			version: json.decode(at: "version") as DocumentVersion,
			work: json.decode(at: "work", type: Work.self),
			editedElement: json.decode(at: "editedElement", alongPath: .missingKeyBecomesNil),
			stageEditingMode: json.decode(at: "stageEditingMode"),
			shapeStyleUUIDForCreating: json.getString(at: "shapeStyleUUIDForCreating", alongPath: .missingKeyBecomesNil).flatMap(UUID.`init`(uuidString:))
		)
	}
	
	func toJSON() -> JSON {
		return .dictionary([
			"version": version.toJSON(),
			"work": work.toJSON(),
			"editedElement": editedElement.toJSON(),
			"stageEditingMode": stageEditingMode.toJSON(),
			"shapeStyleUUIDForCreating": shapeStyleUUIDForCreating.toJSON()
		])
	}
}


class DocumentStateController {
	var displayError: ((Swift.Error) -> ())!
	var undoManager: UndoManager!
	
	var state = DocumentState()
	
	var activeToolIdentifier: CanvasToolIdentifier = .move {
		didSet {
			eventListeners.send(
				.activeToolChanged(toolIdentifier: activeToolIdentifier)
			)
		}
	}
	
	var eventListeners = EventListeners<WorkControllerEvent>()
	
	fileprivate var contentLoader: ContentLoader!
	
	init() {
		contentLoader = ContentLoader(
			contentDidLoad: self.contentDidLoad,
			localContentDidHash: self.localContentDidHash,
			didErr: self.didErrLoading,
			callbackService: .main
		)
	}
}

extension DocumentStateController {
	func contentDidLoad(_ contentReference: ContentReference) {
		eventListeners.send(
			.contentLoaded(contentReference: contentReference)
		)
	}
	
	func localContentDidHash(_ fileURL: URL) {
		// TODO
	}
	
	func didErrLoading(_ error: Swift.Error) {
		displayError(error)
	}
}

extension DocumentStateController {
	func addEventListener(_ createReceiver: (_ unsubscriber: @escaping Unsubscriber) -> ((WorkControllerEvent) -> ())) {
		eventListeners.add(createReceiver)
	}
	
	func sendEvent(_ event: WorkControllerEvent) {
		eventListeners.send(event)
	}
}

extension DocumentStateController {
	fileprivate func changeWork(_ work: Work, change: WorkChange) {
		let oldWork = state.work!
		
		if let undoManager = undoManager {
			undoManager.registerUndoWithCommand {
				[weak self] in
				self?.changeWork(oldWork, change: change)
			}
			
			undoManager.setActionName("Graphics changed")
		}
		
		state.work = work
		
		eventListeners.send(.workChanged(work: work, change: change))
	}
	
	func alterWork(_ alteration: WorkAlteration, change: WorkChange) {
		var work = state.work!
		
		do {
			try work.alter(alteration)
		}
		catch let error {
			displayError?(error)
		}
		
		changeWork(work, change: change)
	}
	
	func alterContentReferences(_ alteration: ElementListAlteration<ContentReference>) {
		print("alterContentReferences")
		let workAlteration = WorkAlteration.alterContentReferences(alteration)
		let change = WorkChange.contentReferences(instanceUUIDs: alteration.affectedUUIDs)
		
		alterWork(workAlteration, change: change)
	}
	
	func alterActiveSection(_ sectionAlteration: SectionAlteration) {
		guard case let .stage(sectionUUID, _)? = state.editedElement else {
			return
		}
		
		let workAlteration = WorkAlteration.alterSections(
			.alterElement(
				uuid: sectionUUID,
				alteration: sectionAlteration
			)
		)
		
		var change: WorkChange
		
		switch sectionAlteration {
		case let .alterContentConstructs(contentConstructsAlteration):
			change = .contentConstructs(
				sectionUUID: sectionUUID,
				instanceUUIDs: contentConstructsAlteration.affectedUUIDs
			)
		default:
			change = .section(
				sectionUUID: sectionUUID
			)
		}
		
		alterWork(workAlteration, change: change)
	}
	
	func alterActiveStage(_ stageAlteration: StageAlteration) {
		guard case let .stage(sectionUUID, stageUUID)? = state.editedElement else {
			return
		}
		
		let workAlteration = WorkAlteration.alterSections(
			.alterElement(
				uuid: sectionUUID,
				alteration: .alterStages(
					.alterElement(
						uuid: stageUUID,
						alteration: stageAlteration
					)
				)
			)
		)
		
		var change: WorkChange
		
		print("stageAlteration", stageAlteration)
		
		switch stageAlteration {
		case let .alterGuideConstructs(guideConstructsAlteration):
			change = .guideConstructs(
				sectionUUID: sectionUUID,
				stageUUID: stageUUID,
				instanceUUIDs: guideConstructsAlteration.affectedUUIDs
			)
		case let .alterGraphicConstructs(graphicConstructsAlteration):
			change = .graphics(
				sectionUUID: sectionUUID,
				stageUUID: stageUUID,
				instanceUUIDs: graphicConstructsAlteration.affectedUUIDs
			)
		default:
			change = .stage(
				sectionUUID: sectionUUID,
				stageUUID: stageUUID
			)
		}
		
		alterWork(workAlteration, change: change)
	}
	
	fileprivate func setStageEditingMode(_ stageEditingMode: StageEditingMode) {
		state.stageEditingMode = stageEditingMode
		
		eventListeners.send(.stageEditingModeChanged(stageEditingMode: stageEditingMode))
	}
	
	fileprivate func processAction(_ action: WorkControllerAction) {
		switch action {
		case let .alterWork(alteration):
			alterWork(alteration, change: .entirety)
		case let .alterActiveStage(alteration):
			alterActiveStage(alteration)
		case let .alterActiveGraphicConstructs(alteration):
			alterActiveStage(
				.alterGraphicConstructs(alteration)
			)
		case let .changeStageEditingMode(mode):
			setStageEditingMode(mode)
		default:
			fatalError("Unimplemented")
		}
	}
	
	func dispatchAction(_ action: WorkControllerAction) {
		DispatchQueue.main.async{
			self.processAction(action)
		}
	}
}

extension DocumentStateController : WorkControllerQuerying {
	var work: Work {
		return state.work
	}
	
	var editedSection: (section: Section, sectionUUID: UUID)? {
		switch state.editedElement {
		case let .stage(sectionUUID, _)?:
			return work.sections[sectionUUID].map{ (
				section: $0,
				sectionUUID: sectionUUID
			) }
		default:
			return nil
		}
	}
	
	var editedStage: (stage: Stage, sectionUUID: UUID, stageUUID: UUID)? {
		switch state.editedElement {
		case let .stage(sectionUUID, stageUUID)?:
			return work.sections[sectionUUID]?.stages[stageUUID].map{ (
				stage: $0,
				sectionUUID: sectionUUID,
				stageUUID: stageUUID
			) }
		default:
			return nil
		}
	}
	
	var stageEditingMode: StageEditingMode {
		return state.stageEditingMode
	}
	
	func catalogWithUUID(_ uuid: UUID) -> Catalog? {
		if (uuid == state.work.catalog.uuid as UUID) {
			return state.work.catalog
		}
		
		return nil
	}
	
	var shapeStyleUUIDForCreating: UUID? {
		return state.shapeStyleUUIDForCreating
	}
	
	func loadedContentForReference(_ contentReference: ContentReference) -> LoadedContent? {
		return contentLoader[contentReference]
	}
	
	func loadedContentForLocalUUID(_ uuid: UUID) -> LoadedContent? {
		guard let contentReference = work.contentReferences[uuid] else {
			// TODO: throw error?
			return nil
		}
		
		return contentLoader[contentReference]
	}
}

extension DocumentStateController {
	func setUpDefault() {
		print("setUpDefault")
		// MARK: Catalog
		
		let catalogUUID = UUID()
		var catalog = Catalog(uuid: catalogUUID)
		
		let defaultShapeStyle = ShapeStyleDefinition(
			fillColorReference: ElementReferenceSource.direct(element: Color.sRGB(r: 0.8, g: 0.9, b: 0.3, a: 0.8)),
			lineWidth: 1.0,
			strokeColor: Color.sRGB(r: 0.8, g: 0.9, b: 0.3, a: 0.8)
		)
		let defaultShapeStyleUUID = UUID()
		catalog.makeAlteration(.addShapeStyle(UUID: defaultShapeStyleUUID, shapeStyle: defaultShapeStyle, info: nil))
		
		state.shapeStyleUUIDForCreating = defaultShapeStyleUUID
		
		// MARK: Work
		
		var work = Work()
		work.catalog = catalog
		
		func stageWithHashtag(_ hashtag: Hashtag) -> Stage {
			return Stage(
				hashtags: [
					hashtag
				],
				name: nil,
				bounds: nil,
				guideConstructs: [
					GuideConstruct.freeform(
						created: .rectangle(rectangle: .originWidthHeight(origin: .zero, width: 320, height: 568)),
						createdUUID: UUID()
					)
				],
				guideTransforms: [],
				graphicConstructs: []
			)
		}
		
		let section = Section(
			stages: [
				stageWithHashtag(.text("empty")),
				stageWithHashtag(.text("filled"))
			],
			hashtags: [],
			name: "Home",
			contentInputs: [],
			contentConstructs: [
				ContentConstruct.text(text: .value("Example"))
			]
		)
		
		let sectionUUID = UUID()
		let stageUUID = section.stages.items[0].uuid
		
		try! work.alter(
			.alterSections(.add(element: section, uuid: sectionUUID, index: 0))
		)
		
		try! work.usedCatalogItems.usedShapeStyles.alter(.add(
			element: CatalogItemReference(
				itemKind: StyleKind.FillAndStroke,
				itemUUID: defaultShapeStyleUUID,
				catalogUUID: catalogUUID
			),
			uuid: defaultShapeStyleUUID,
			index: 0
		))
		
		state.version = DocumentVersion(version: 0, revision: 1)
		state.work = work
		state.editedElement = .stage(sectionUUID: sectionUUID, stageUUID: stageUUID as UUID)
	}
}

extension DocumentStateController {
	enum Error : Swift.Error {
		case sourceJSONParsing(JSON.Error)
		case sourceJSONDecoding(JSON.Error)
		case sourceJSONInvalid
		case sourceJSONMissingKey(String)
		case jsonSerialization
	}
	
	func JSONData() throws -> Data {
		let json = state.toJSON()
		guard let data = try? json.serialize()
			else { throw Error.jsonSerialization }
		
		return data
	}
	
	func readFromJSONData(_ data: Data) throws {
		//let source = NSJSONSerialization.JSONObjectWithData(data, options: [])
		
		do {
			let json = try JSONParser.createJSON(from: data)
			state = try DocumentState(json: json)
		}
		catch let error as JSON.Error {
			print("Error opening document (parsing/decoding) \(error)")
			
			throw Error.sourceJSONParsing(error)
		}
		catch {
			throw Error.sourceJSONInvalid
		}
	}
}

extension DocumentStateController {
	func addContentReference(_ contentReference: ContentReference, instanceUUID: UUID = UUID()) -> UUID {
		alterContentReferences(
			.add(
				element: contentReference,
				uuid: instanceUUID,
				index: nil
			)
		)
		
		return instanceUUID
	}
	
	func addGraphicConstruct(_ graphicConstruct: GraphicConstruct, instanceUUID: UUID = UUID()) {
		alterActiveStage(
			.alterGraphicConstructs(
				.add(
					element: graphicConstruct,
					uuid: instanceUUID,
					index: nil
				)
			)
		)
	}
	
	func importImages(_ fileURLs: [URL]) {
		for fileURL in fileURLs {
			guard let contentType = ContentType(fileExtension: fileURL.pathExtension)
				else {
					// TODO: show error
					print(ContentType(fileExtension: fileURL.pathExtension))
					continue
			}
			
			// TODO: copy local file to a catalog
			
			self.contentLoader.addLocalFile(fileURL) {
				sha256 in
				
				print("sha256", sha256)
				
				let contentReference = ContentReference.localSHA256(sha256: sha256, contentType: contentType)
				self.contentLoader.load(contentReference) {
					loadedContent in
					
					guard case let .bitmapImage(loadedImage) = loadedContent else {
						// TODO: SHOW ERROR
						return
					}
					
					let contentReferenceUUID = self.addContentReference(contentReference)
					
					self.alterActiveSection(
						.alterContentConstructs(
							.add(
								element: ContentConstruct.image(contentReferenceUUID: contentReferenceUUID),
								uuid: UUID(),
								index: nil
							)
						)
					)
					
					self.addGraphicConstruct(
						GraphicConstruct.freeform(
							created: .image(
								// FIXME: cahnge to contentReferenceUUID / contentUUID / imageUUID
								contentReference: contentReference,
								origin: .zero,
								size: loadedImage.size,
								imageStyleUUID: UUID() /* FIXME */
							),
							createdUUID: UUID()
						)
					)
				}
			}
		}
	}
	
	func importTexts(_ fileURLs: [URL]) {
		for fileURL in fileURLs {
			guard let contentType = ContentType(fileExtension: fileURL.pathExtension)
				else {
					// TODO: show error
					print(ContentType(fileExtension: fileURL.pathExtension))
					continue
			}
			
			// TODO: copy local file to a catalog
			
			self.contentLoader.addLocalFile(fileURL) { sha256 in
				print("sha256", sha256)
				
				let contentReference = ContentReference.localSHA256(sha256: sha256, contentType: contentType)
				self.contentLoader.load(contentReference) {
					loadedContent in
					
					// FIXME: allow any file extension
					switch loadedContent {
					case .text, .markdown:
						break
					default:
						print("Unknown type")
						return
					}

					
					let contentReferenceUUID = self.addContentReference(contentReference)
					
					self.alterActiveSection(
						.alterContentConstructs(
							.add(
								element: ContentConstruct.text(text: .uuid(contentReferenceUUID)),
								uuid: UUID(),
								index: nil
							)
						)
					)
					
					self.addGraphicConstruct(
						GraphicConstruct.freeform(
							created: .text(
								textReference: .uuid(contentReferenceUUID),
								origin: .zero,
								size: Dimension2D(x: 200.0, y: 300.0),
								textStyleUUID: UUID() /* FIXME */
							),
							createdUUID: UUID()
						)
					)
				}
			}
		}
	}
}
