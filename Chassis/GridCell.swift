//
//  GridCell.swift
//  Chassis
//
//  Created by Patrick Smith on 1/01/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


struct GridRun {
	typealias Index = Int
	
	var startIndex: Index
	var endIndex: Index?
	var individualSpan: Dimension
	
	struct OffsetView: CollectionType {
		typealias Index = Int
		
		var gridRun: GridRun
		
		var startIndex: Index {
			return gridRun.startIndex
		}
		
		var endIndex: Index {
			return gridRun.endIndex ?? Int.max
		}
		
		subscript(position: Int) -> Dimension {
			return Dimension(position) * gridRun.individualSpan
		}
		
		func generate() -> IndexingGenerator<OffsetView> {
			return IndexingGenerator(self)
		}
	}
}


struct GridCell {
	var columnIndex: Int
	var rowIndex: Int
	var columnSpan: Dimension
	var rowSpan: Dimension
}
