//
//  GridCell.swift
//  Chassis
//
//  Created by Patrick Smith on 1/01/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation
import Freddy


struct SpanRun {
	typealias Index = Int
	
	var startIndex: Index
	var endIndex: Index?
	var individualSpan: Dimension
	
	struct OffsetView: Collection {
		typealias Index = Int
		typealias SubSequence = Slice<OffsetView>
		
		fileprivate var spanRun: SpanRun
		
		var startIndex: Index {
			return spanRun.startIndex
		}
		
		var endIndex: Index {
			return spanRun.endIndex ?? Int.max
		}
		
		func index(after i: Int) -> Int {
			return i + 1
		}
		
		subscript(position: Int) -> Dimension {
			return Dimension(position) * spanRun.individualSpan
		}
		
//		func makeIterator() -> IndexingIterator<OffsetView> {
//			return IndexingIterator(self)
//		}
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

extension Grid : JSONRepresentable {
	public init(json: JSON) throws {
		try self.init(
			width: json.decode(at: "width"),
			height: json.decode(at: "height"),
			xDivision: json.decode(at: "xDivision"),
			yDivision: json.decode(at: "yDivision"),
			xFrom: json.decode(at: "xFrom"),
			yFrom: json.decode(at: "yFrom"),
			direction: json.decode(at: "direction")
		)
	}
	
	public func toJSON() -> JSON {
		return .dictionary([
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
	public struct Index : Comparable {
		public var column: Int
		public var row: Int
		fileprivate var grid: Grid
		
		public static func < (lhs: Index, rhs: Index) -> Bool {
			if lhs.row != rhs.row {
				return lhs.row < rhs.row
			} else {
				return lhs.column < rhs.column
			}
		}
		
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
		fileprivate var grid: Grid
		
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
