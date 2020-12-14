//
//  FaveButton.swift
//  FaveButton
//
// Copyright © 2016 Jansel Valentin.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit

public typealias DotColors = (first: UIColor, second: UIColor)

public protocol FaveButtonDelegate {
  func faveButton(_ faveButton: FaveButton, didSelected selected: Bool)

  func faveButtonDotColors(_ faveButton: FaveButton) -> [DotColors]?
}

// MARK: Default implementation

public extension FaveButtonDelegate {
  func faveButtonDotColors(_ faveButton: FaveButton) -> [DotColors]? { nil }
}

open class FaveButton: UIButton {
  fileprivate enum Const {
    static let duration = 1.0
    static let expandDuration = 0.1298
    static let collapseDuration = 0.1089
    static let faveIconShowDelay = Const.expandDuration + Const.collapseDuration/2.0
    static let dotRadiusFactors = (first: 0.0633, second: 0.04)
  }

  @IBInspectable open var normalColor = UIColor(red: 137/255, green: 156/255, blue: 167/255, alpha: 1)
  @IBInspectable open var selectedColor = UIColor(red: 226/255, green: 38/255, blue: 77/255, alpha: 1)
  @IBInspectable open var dotFirstColor = UIColor(red: 152/255, green: 219/255, blue: 236/255, alpha: 1)
  @IBInspectable open var dotSecondColor = UIColor(red: 247/255, green: 188/255, blue: 48/255, alpha: 1)
  @IBInspectable open var circleFromColor = UIColor(red: 221/255, green: 70/255, blue: 136/255, alpha: 1)
  @IBInspectable open var circleToColor = UIColor(red: 205/255, green: 143/255, blue: 246/255, alpha: 1)
  @IBInspectable open var selectedImage: UIImage?

  @IBOutlet open weak var delegate: AnyObject?

  fileprivate(set) var sparkGroupCount: Int = 7

  fileprivate var faveIconImage: UIImage?
  fileprivate var contentRectOverride: CGRect?
  fileprivate var faveIcon: FaveIcon!
  fileprivate var animationsEnabled = true

  override open var isSelected: Bool {
    didSet {
      guard animationsEnabled else {
        return
      }

      animateSelect(isSelected, duration: Const.duration)
    }
  }

  public convenience init(
    frame: CGRect,
    normalImage: UIImage?,
    selectedImage: UIImage?,
    normalColor: UIColor? = nil,
    selectedColor: UIColor? = nil,
    dotFirstColor: UIColor? = nil,
    dotSecondColor: UIColor? = nil,
    circleFromColor: UIColor? = nil,
    circleToColor: UIColor? = nil
  ) {
    self.init(frame: frame)

    guard let icon = normalImage else {
      fatalError("missing image for normal state")
    }
    faveIconImage = icon
    self.selectedImage = selectedImage ?? self.selectedImage
    self.normalColor = normalColor ?? self.normalColor
    self.selectedColor = selectedColor ?? self.selectedColor
    self.dotFirstColor = dotFirstColor ?? self.dotFirstColor
    self.dotSecondColor = dotSecondColor ?? self.dotSecondColor
    self.circleFromColor = circleFromColor ?? self.circleFromColor
    self.circleToColor = circleToColor ?? self.circleToColor

    applyInit()
  }

  override public init(frame: CGRect) {
    super.init(frame: frame)
  }

  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  override open func awakeFromNib() {
    super.awakeFromNib()
    applyInit()
  }

  public func setSelected(selected: Bool, animated: Bool) {
    guard selected != isSelected else {
      return
    }
    guard animated == false else {
      isSelected = selected
      return
    }

    animationsEnabled = false
    isSelected = selected
    animationsEnabled = true

    animateSelect(isSelected, duration: 0.0) // trigger state change without animation
  }
}

// MARK: create

private extension FaveButton {
  func applyInit() {
    if faveIconImage == nil {
      faveIconImage = image(for: .normal)
    }

    guard let faveIconImage = faveIconImage else {
      fatalError("please provide an image for normal state.")
    }

    setImage(UIImage(), for: .normal)
    setImage(UIImage(), for: .selected)
    setTitle(nil, for: .normal)
    setTitle(nil, for: .selected)

    faveIcon = createFaveIcon(faveIconImage)

    addActions()
  }

  func createFaveIcon(_ faveIconImage: UIImage) -> FaveIcon {
    FaveIcon.createFaveIcon(self, icon: faveIconImage, color: normalColor, selectedIcon: selectedImage)
  }

  func createSparks(_ radius: CGFloat) -> [Spark] {
    var sparks = [Spark]()
    let step = 360.0/Double(sparkGroupCount)
    let base = Double(bounds.size.width)
    let dotRadius = (base * Const.dotRadiusFactors.first, base * Const.dotRadiusFactors.second)
    let offset = 10.0

    for index in 0..<sparkGroupCount {
      let theta = step * Double(index) + offset
      let colors = dotColors(atIndex: index)

      let spark = Spark.createSpark(self, radius: radius, firstColor: colors.first, secondColor: colors.second, angle: theta,
                                    dotRadius: dotRadius)
      sparks.append(spark)
    }
    return sparks
  }
}

// MARK: utils

private extension FaveButton {
  func dotColors(atIndex index: Int) -> DotColors {
    if case let delegate as FaveButtonDelegate = delegate, delegate.faveButtonDotColors(self) != nil {
      let colors = delegate.faveButtonDotColors(self)!
      let colorIndex = 0..<colors.count ~= index ? index : index % colors.count

      return colors[colorIndex]
    }
    return DotColors(dotFirstColor, dotSecondColor)
  }
}

// MARK: actions

extension FaveButton {
  func addActions() {
    addTarget(self, action: #selector(toggle(_:)), for: .touchUpInside)
  }

  @objc func toggle(_ sender: FaveButton) {
    sender.isSelected = !sender.isSelected

    guard case let delegate as FaveButtonDelegate = self.delegate else {
      return
    }

    let delay = DispatchTime.now() + Double(Int64(Double(NSEC_PER_SEC) * Const.duration))/Double(NSEC_PER_SEC)
    DispatchQueue.main.asyncAfter(deadline: delay) {
      delegate.faveButton(sender, didSelected: sender.isSelected)
    }
  }
}

// MARK: animation

private extension FaveButton {
  func animateSelect(_ isSelected: Bool, duration: Double) {
    let color = isSelected ? selectedColor : normalColor

    faveIcon.animateSelect(isSelected, fillColor: color, duration: duration, delay: duration > 0.0 ? Const.faveIconShowDelay : 0.0)

    guard duration > 0.0 else {
      return
    }

    if isSelected {
      let width = bounds.size.width - contentEdgeInsets.left - contentEdgeInsets.right
      let radius = (width * 1.3)/2 // ring radius
      let igniteFromRadius = radius * 0.8
      let igniteToRadius = radius * 1.1

      let ring = Ring.createRing(self, radius: 0.01, lineWidth: 3, fillColor: circleFromColor)
      let sparks = createSparks(igniteFromRadius)

      ring.animateToRadius(radius, toColor: circleToColor, duration: Const.expandDuration, delay: 0)
      ring.animateColapse(radius, duration: Const.collapseDuration, delay: Const.expandDuration)

      sparks.forEach {
        $0.animateIgniteShow(igniteToRadius, duration: 0.4, delay: Const.collapseDuration/3.0)
        $0.animateIgniteHide(0.7, delay: 0.2)
      }
    }
  }
}
