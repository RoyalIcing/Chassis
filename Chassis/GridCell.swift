//
//  GridCell.swift
//  Chassis
//
//  Created by Patrick Smith on 1/01/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


struct SpanRun {
	typealias Index = Int
	
	var startIndex: Index
	var endIndex: Index?
	var individualSpan: Dimension
	
	struct OffsetView: CollectionType {
		typealias Index = Int
		typealias SubSequence = Slice<OffsetView>
		
		private var spanRun: SpanRun
		
		var startIndex: Index {
			return spanRun.startIndex
		}
		
		var endIndex: Index {
			return spanRun.endIndex ?? Int.max
		}
		
		subscript(position: Int) -> Dimension {
			return Dimension(position) * spanRun.individualSpan
		}
		
		func generate() -> IndexingGenerator<OffsetView> {
			return IndexingGenerator(self)
		}
	}
	
	var offsets: OffsetView {
		return OffsetView(spanRun: self)
	}
}


struct GridCell {
	var columnIndex: Int
	var rowIndex: Int
	var columnSpan: Dimension
	var rowSpan: Dimension
}


struct GridRun {
	var columnsRun: SpanRun
	var rowsRun: SpanRun
}


/*
struct ValueProducer<Value> {
	var value: Value
}

struct CellProducer {
	var width: ValueProducer<Dimension>
	var height: ValueProducer<Dimension>
}
*/