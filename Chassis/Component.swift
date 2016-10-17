//
//  Component.swift
//  Chassis
//
//  Created by Patrick Smith on 17/05/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


// TODO: refactor into Component???
public struct Component : ElementType {
  public var hashtags = ElementList<Hashtag>()
  public var name: String? = nil
  
  // CONTENT
  public var contentInputs = ElementList<ContentInput>()
  
  public var contentChoices: ElementList<ComponentContentChoice>
  
  // LAYOUT
  public var guideConstructs: ElementList<GuideConstruct>
  public var guideTransforms: ElementList<GuideTransform>
  
  // VISUALS
  public var graphicConstructs: ElementList<GraphicConstruct>
}


public struct ComponentContentChoice : ElementType {
  public var hashtags = ElementList<Hashtag>()
  public var name: String? = nil
  
  public var contentConstructs: ElementList<ContentConstruct>
}
