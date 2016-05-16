//
//  DocumentState.swift
//  Chassis
//
//  Created by Patrick Smith on 8/03/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation
import Grain


enum EditedElement {
	case stage(sectionUUID: NSUUID, stageUUID: NSUUID)
	
	//case graphicComponent(NSUUID)
}

extension EditedElement : JSONObjectRepresentable {
	init(source: JSONObjectDecoder) throws {
		self = try source.decodeChoices(
	  { try .stage(sectionUUID: $0.decodeUUID("sectionUUID"), stageUUID: $0.decodeUUID("stageUUID")) }
		)
	}
	
	func toJSON() -> JSON {
		switch self {
		case let .stage(sectionUUID, stageUUID):
			return .ObjectValue([
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

extension DocumentVersion : JSONObjectRepresentable {
	init(source: JSONObjectDecoder) throws {
		try self.init(
			version: source.decode("version"),
			revision: source.decode("revision")
		)
	}
	
	func toJSON() -> JSON {
		return .ObjectValue([
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
	
	var shapeStyleUUIDForCreating: NSUUID?
}

extension DocumentState: JSONObjectRepresentable {
	init(source: JSONObjectDecoder) throws {
		try self.init(
			version: source.decode("version") as DocumentVersion,
			work: source.decode("work") as Work,
			editedElement: source.decodeOptional("editedElement"),
			stageEditingMode: source.decode("stageEditingMode"),
			shapeStyleUUIDForCreating: source.optional("shapeStyleUUIDForCreating")?.decodeStringUsing(NSUUID.init)
		)
	}
	
	func toJSON() -> JSON {
		return .ObjectValue([
			"version": version.toJSON(),
			"work": work.toJSON(),
			"editedElement": editedElement.toJSON(),
			"stageEditingMode": stageEditingMode.toJSON(),
			"shapeStyleUUIDForCreating": shapeStyleUUIDForCreating.toJSON()
		])
	}
}


class DocumentStateController {
	var displayError: ((ErrorType) -> ())!
	var undoManager: NSUndoManager!
	
	var state = DocumentState()
	
	var activeToolIdentifier: CanvasToolIdentifier = .Move {
		didSet {
			eventListeners.send(
				.activeToolChanged(toolIdentifier: activeToolIdentifier)
			)
		}
	}
	
	var eventListeners = EventListeners<WorkControllerEvent>()
	
	private var contentLoader: ContentLoader!
	
	init() {
		contentLoader = ContentLoader(
			contentDidLoad: self.contentDidLoad,
			localContentDidHash: self.localContentDidHash,
			didErr: self.didErrLoading,
			callbackService: .mainQueue
		)
	}
}

extension DocumentStateController {
	func contentDidLoad(contentReference: ContentReference) {
		eventListeners.send(
			.contentLoaded(contentReference: contentReference)
		)
	}
	
	func localContentDidHash(fileURL: NSURL) {
		// TODO
	}
	
	func didErrLoading(error: ErrorType) {
		displayError(error)
	}
}

extension DocumentStateController {
	func addEventListener(createReceiver: (unsubscriber: Unsubscriber) -> (WorkControllerEvent -> ())) {
		eventListeners.add(createReceiver)
	}
	
	func sendEvent(event: WorkControllerEvent) {
		eventListeners.send(event)
	}
}

extension DocumentStateController {
	private func changeWork(work: Work, change: WorkChange) {
		let oldWork = state.work
		
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
	
	func alterWork(alteration: WorkAlteration, change: WorkChange) {
		var work = state.work
		
		do {
			try work.alter(alteration)
		}
		catch {
			displayError(error)
		}
		
		changeWork(work, change: change)
	}
	
	func alterContentReferences(alteration: ElementListAlteration<ContentReference>) {
		print("alterContentReferences")
		let workAlteration = WorkAlteration.alterContentReferences(alteration)
		let change = WorkChange.contentReferences(instanceUUIDs: alteration.affectedUUIDs)
		
		alterWork(workAlteration, change: change)
	}
	
	func alterActiveSection(sectionAlteration: SectionAlteration) {
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
	
	func alterActiveStage(stageAlteration: StageAlteration) {
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
	
	private func setStageEditingMode(stageEditingMode: StageEditingMode) {
		state.stageEditingMode = stageEditingMode
		
		eventListeners.send(.stageEditingModeChanged(stageEditingMode: stageEditingMode))
	}
	
	private func processAction(action: WorkControllerAction) {
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
	
	func dispatchAction(action: WorkControllerAction) {
		GCDService.mainQueue.async{
			self.processAction(action)
		}
	}
}

extension DocumentStateController : WorkControllerQuerying {
	var work: Work {
		return state.work
	}
	
	var editedSection: (section: Section, sectionUUID: NSUUID)? {
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
	
	var editedStage: (stage: Stage, sectionUUID: NSUUID, stageUUID: NSUUID)? {
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
	
	func catalogWithUUID(uuid: NSUUID) -> Catalog? {
		if (uuid == state.work.catalog.UUID) {
			return state.work.catalog
		}
		
		return nil
	}
	
	var shapeStyleUUIDForCreating: NSUUID? {
		return state.shapeStyleUUIDForCreating
	}
	
	func loadedContentForReference(contentReference: ContentReference) -> LoadedContent? {
		return contentLoader[contentReference]
	}
	
	func loadedContentForLocalUUID(uuid: NSUUID) -> LoadedContent? {
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
		
		let catalogUUID = NSUUID()
		var catalog = Catalog(UUID: catalogUUID)
		
		let defaultShapeStyle = ShapeStyleDefinition(
			fillColorReference: ElementReferenceSource.Direct(element: Color.sRGB(r: 0.8, g: 0.9, b: 0.3, a: 0.8)),
			lineWidth: 1.0,
			strokeColor: Color.sRGB(r: 0.8, g: 0.9, b: 0.3, a: 0.8)
		)
		let defaultShapeStyleUUID = NSUUID()
		catalog.makeAlteration(.AddShapeStyle(UUID: defaultShapeStyleUUID, shapeStyle: defaultShapeStyle, info: nil))
		
		state.shapeStyleUUIDForCreating = defaultShapeStyleUUID
		
		// MARK: Work
		
		var work = Work()
		work.catalog = catalog
		
		func stageWithHashtag(hashtag: Hashtag) -> Stage {
			return Stage(
				hashtags: [
					hashtag
				],
				name: nil,
				bounds: nil,
				guideConstructs: [
					GuideConstruct.freeform(
						created: .rectangle(rectangle: .originWidthHeight(origin: .zero, width: 320, height: 568)),
						createdUUID: NSUUID()
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
		
		let sectionUUID = NSUUID()
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
		state.editedElement = .stage(sectionUUID: sectionUUID, stageUUID: stageUUID)
	}
}

extension DocumentStateController {
	enum Error: ErrorType {
		case sourceJSONParsing(JSONParseError)
		case sourceJSONDecoding(JSONDecodeError)
		case sourceJSONInvalid
		case sourceJSONMissingKey(String)
		case jsonSerialization
	}
	
	func JSONData() throws -> NSData {
		let json = state.toJSON()
		let serializer = DefaultJSONSerializer()
		let string = serializer.serialize(json)
		
		guard let data = string.dataUsingEncoding(NSUTF8StringEncoding) else {
			throw Error.jsonSerialization
		}
		
		return data
	}
	
	func readFromJSONData(data: NSData) throws {
		//let source = NSJSONSerialization.JSONObjectWithData(data, options: [])
		
		let bytesPointer = UnsafePointer<UInt8>(data.bytes)
		let buffer = UnsafeBufferPointer(start: bytesPointer, count: data.length)
		
		let parser = GenericJSONParser(buffer)
		do {
			let sourceJSON = try parser.parse()
			
			guard let sourceDecoder = sourceJSON.objectDecoder else {
				throw Error.sourceJSONInvalid
			}
			
			state = try DocumentState(source: sourceDecoder)
		}
		catch let error as JSONParseError {
			print("Error opening document (parsing) \(error)")
			
			throw Error.sourceJSONParsing(error)
		}
		catch let error as JSONDecodeError {
			print("Error opening document (decoding) \(error)")
			
			throw Error.sourceJSONDecoding(error)
		}
		catch {
			throw Error.sourceJSONInvalid
		}
	}
}

extension DocumentStateController {
	func addContentReference(contentReference: ContentReference, instanceUUID: NSUUID = NSUUID()) -> NSUUID {
		alterContentReferences(
			.add(
				element: contentReference,
				uuid: instanceUUID,
				index: nil
			)
		)
		
		return instanceUUID
	}
	
	func addGraphicConstruct(graphicConstruct: GraphicConstruct, instanceUUID: NSUUID = NSUUID()) {
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
	
	func importImages(fileURLs: [NSURL]) {
		for fileURL in fileURLs {
			guard let
				fileExtension = fileURL.pathExtension,
				contentType = ContentType(fileExtension: fileExtension)
				else {
					// TODO: show error
					print(ContentType(fileExtension: fileURL.pathExtension!))
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
								uuid: NSUUID(),
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
								imageStyleUUID: NSUUID() /* FIXME */
							),
							createdUUID: NSUUID()
						)
					)
				}
			}
		}
	}
	
	func importTexts(fileURLs: [NSURL]) {
		for fileURL in fileURLs {
			guard let
				fileExtension = fileURL.pathExtension,
				contentType = ContentType(fileExtension: fileExtension)
				else {
					// TODO: show error
					print(ContentType(fileExtension: fileURL.pathExtension!))
					continue
			}
			
			// TODO: copy local file to a catalog
			
			self.contentLoader.addLocalFile(fileURL) {
				sha256 in
				
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
								uuid: NSUUID(),
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
								textStyleUUID: NSUUID() /* FIXME */
							),
							createdUUID: NSUUID()
						)
					)
				}
			}
		}
	}
}
