//
//  Designation.swift
//  Chassis
//
//  Created by Patrick Smith on 4/10/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation

public enum Designation {
	case Text(String)
	case Index(number: Int, kind: IndexKind)
	
	public enum IndexKind { // TODO: rename
		case Cardinal // 1, 2, 3
		case Ordinal // 1st, 2nd, 3rd
		case RomanNumerals(lowercase: Bool) // I, II, III
	}
}

public enum DesignationReference {
	case Direct(designation: Designation)
	case Cataloged(sourceUUID: NSUUID, catalogUUID: NSUUID)
}
