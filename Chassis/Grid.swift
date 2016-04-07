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


public enum GridDirection : String, KindType {
	case rows = "rows" // Across rows, like brickwork
	case columns = "columns" // Down columns, like coin stacks
}

public enum RunAlign : String, KindType {
	case start = "start"
	case end = "end"
}

public struct Grid {
	// TODO: put width in xDivision, height in yDivision?
	public var width: Dimension
	public var height: Dimension
	public var xDivision: SpanDivision
	public var yDivision: SpanDivision
	public var xFrom: RunAlign
	public var yFrom: RunAlign
	public var direction: GridDirection
}

extension Grid : ElementType {
	public var kind: SingleKind {
		return .sole
	}
	
	public typealias Alteration = NoAlteration
}

extension Grid : JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		try self.init(
			width: source.decode("width"),
			height: source.decode("height"),
			xDivision: source.decode("xDivision"),
			yDivision: source.decode("yDivision"),
			xFrom: source.decode("xFrom"),
			yFrom: source.decode("yFrom"),
			direction: source.decode("direction")
		)
	}
	
	public func toJSON() -> JSON {
		return .ObjectValue([
			"width": width.toJSON(),
			"height": height.toJSON(),
			"xDivision": xDivision.toJSON(),
			"yDivision": yDivision.toJSON(),
			"xFrom": xFrom.toJSON(),
			"yFrom": yFrom.toJSON(),
			"direction": direction.toJSON()
		])
	}
}

extension Grid {
	public struct Index : ForwardIndexType {
		public var column: Int
		public var row: Int
		private var grid: Grid
		
		public func successor() -> Index {
			switch grid.direction {
			case .rows:
				let nextColumn = column + 1
				if nextColumn == grid.xDivision.endIndex {
					return Index(column: grid.xDivision.startIndex, row: row + 1, grid: grid)
				}
				else {
					return Index(column: nextColumn, row: row, grid: grid)
				}
			case .columns:
				let nextRow = row + 1
				if nextRow == grid.yDivision.endIndex {
					return Index(column: column + 1, row: grid.yDivision.startIndex, grid: grid)
				}
				else {
					return Index(column: column, row: nextRow, grid: grid)
				}
			}
		}
	}
	
	public var startIndex: Index {
		return Index(column: 0, row: 0, grid: self)
	}
	
	public var endIndex: Index {
		switch direction {
		case .rows:
			return Index(column: xDivision.startIndex, row: yDivision.endIndex, grid: self)
		case .columns:
			return Index(column: xDivision.endIndex, row: yDivision.startIndex, grid: self)
		}
	}
	
	public subscript(column: Int, row: Int) -> Index {
		return Index(column: column, row: row, grid: self)
	}
}


public func == (lhs: Grid.Index, rhs: Grid.Index) -> Bool {
	return lhs.column == rhs.column && lhs.row == rhs.row
}

extension Grid {
	public struct CellBounds {
		private var grid: Grid
		
		public var startIndex: Index {
			return grid.startIndex
		}
		
		public var endIndex: Index {
			return grid.endIndex
		}
		
		public subscript(index: Index) -> Rectangle {
			let successor = index.successor()
			
			return Rectangle.minMax(
				minPoint: Point2D(
					x: grid.xDivision[index.column],
					y: grid.yDivision[index.row]
				),
				maxPoint: Point2D(
					x: grid.xDivision[successor.column],
					y: grid.yDivision[successor.row]
				)
			)
		}
	}
	
	public var cellBounds: CellBounds {
		return CellBounds(grid: self)
	}
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