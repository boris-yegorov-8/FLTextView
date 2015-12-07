//
//  FLTextView.swift
//  FLTextView
//
//  Created by Danilo Bürger on 07.04.15.
//  Copyright (c) 2015 Freeletics GmbH (https://www.freeletics.com/)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import UIKit

public class FLTextView: UITextView {
    
    // MARK: - Private Properties
    
    private let placeholderView = UITextView(frame: CGRectZero)
    
    private weak var externalTextViewDelegate: UITextViewDelegate?
    
    private var canResetTextViewDelegate = false
    
    //Stored default font because it's resets after change attributedString
    private var stroredTextFont: UIFont?
    
    //Stored default text coor because it's resets after change attributedString
    private var stroredTextColor: UIColor?
    
    //Default text color
    private let defaultTextColor = UIColor.blackColor()
    
    //Default text color
    private let defaultTextFont = UIFont.systemFontOfSize(UIFont.systemFontSize())
    
    
    // MARK: - Placeholder Properties
    
    //Non-editable and non-delitable prefix which appears after srart typing
    @IBInspectable public var frozenPrefix: String?
    
    //Color for frozen prefix by default uses color of textview text
    @IBInspectable public var frozenPrefixColor: UIColor?
    
    //Font for frozen prefix by default uses font of textview text
    public var frozenPrefixFont: UIFont?
    
    /// If you want to apply the color to only a portion of the placeholder,
    /// you must create a new attributed string with the desired style information
    /// and assign it to the attributedPlaceholder property.
    @IBInspectable public var placeholderTextColor: UIColor? {
        get {
            return placeholderView.textColor
        }
        set {
            placeholderView.textColor = newValue
        }
    }
    
    /// The string that is displayed when there is no other text in the text view.
    @IBInspectable public var placeholder: String? {
        get {
            return placeholderView.text
        }
        set {
            placeholderView.text = newValue
            setNeedsLayout()
        }
    }
    
    /// The styled string that is displayed when there is no other text in the text view.
    public var attributedPlaceholder: NSAttributedString? {
        get {
            return placeholderView.attributedText
        }
        set {
            placeholderView.attributedText = newValue
            setNeedsLayout()
        }
    }
    
    /// Returns true if the placeholder is currently showing.
    public var isShowingPlaceholder: Bool {
        return placeholderView.superview != nil
    }
    
    
    // MARK: - Delegate
    
    override weak public var delegate: UITextViewDelegate? {
        get {
            return self
        }
        set {
            
            if newValue is FLTextView  == false {
                externalTextViewDelegate = newValue
            }
            
            if !canResetTextViewDelegate {
                super.delegate = self
            }
            
        }
        
    }
    
    
    // MARK: - Observed Properties
    
    override public var text: String! {
        didSet {
            showPlaceholderViewIfNeeded()
        }
    }
    
    override public var attributedText: NSAttributedString! {
        didSet {
            showPlaceholderViewIfNeeded()
        }
    }
    
    override public var font: UIFont? {
        didSet {
            stroredTextFont = font
            placeholderView.font = font
        }
    }
    
    override public var textColor: UIColor? {
        didSet {
            stroredTextColor = textColor
        }
    }
    
    override public var textAlignment: NSTextAlignment {
        didSet {
            placeholderView.textAlignment = textAlignment
        }
    }
    
    override public var textContainerInset: UIEdgeInsets {
        didSet {
            placeholderView.textContainerInset = textContainerInset
        }
    }
    
    // MARK: - Initialization
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        delegate = self
        setupPlaceholderView()
    }
    
    override public init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        delegate = self
        setupPlaceholderView()
    }
    
    deinit {
        canResetTextViewDelegate = true
    }

    
    // MARK: - UIView
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        resizePlaceholderView()
    }
    
    public override func intrinsicContentSize() -> CGSize {
        if isShowingPlaceholder {
            return placeholderSize()
        }
        return super.intrinsicContentSize()
    }
    
    // MARK: - Placeholder
    
    private func setupPlaceholderView() {
        placeholderView.opaque = false
        placeholderView.backgroundColor = UIColor.clearColor()
        placeholderView.textColor = UIColor(white: 0.7, alpha: 1.0)
        
        placeholderView.editable = false
        placeholderView.scrollEnabled = true
        placeholderView.userInteractionEnabled = false
        placeholderView.isAccessibilityElement = false
        placeholderView.selectable = false
        
        showPlaceholderViewIfNeeded()
        
        placeholderView.delegate = self
    }
    
    private func showPlaceholderViewIfNeeded() {
        if text != nil && !text.isEmpty {
            if isShowingPlaceholder {
                placeholderView.removeFromSuperview()
                invalidateIntrinsicContentSize()
                setContentOffset(CGPointZero, animated: false)
            }
        } else {
            if !isShowingPlaceholder {
                addSubview(placeholderView)
                invalidateIntrinsicContentSize()
                setContentOffset(CGPointZero, animated: false)
            }
        }
    }
    
    private func resizePlaceholderView() {
        if isShowingPlaceholder {
            let frame = self.bounds
            
            if !CGRectEqualToRect(placeholderView.frame, frame) {
                placeholderView.frame = frame
                invalidateIntrinsicContentSize()
            }
            
            contentInset = UIEdgeInsetsMake(0.0, 0.0, frame.height - contentSize.height, 0.0)
        } else {
            contentInset = UIEdgeInsetsZero
        }
    }
    
    private func placeholderSize() -> CGSize {
        var maxSize = self.bounds.size
        maxSize.height = CGFloat.max
        return placeholderView.sizeThatFits(maxSize)
    }
    
    // MARK: - Frozen text
    
    private func applyStylesForFrozenText() {
        guard let frozenText = frozenPrefix else { return }
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = textAlignment
        
        let isAttributedStringNeed = (frozenPrefixColor != nil || frozenPrefixFont != nil)
        
        if attributedText.string == frozenText && isAttributedStringNeed {
            let attributedString = NSMutableAttributedString(string: "")
            let attrFont = (frozenPrefixFont ?? font) ?? defaultTextFont
            let attrColor = (frozenPrefixColor ?? textColor) ?? defaultTextColor
            let attrs = [NSFontAttributeName : attrFont, NSForegroundColorAttributeName: attrColor, NSParagraphStyleAttributeName : paragraphStyle]
            let frozenAttributedString = NSAttributedString(string:frozenText, attributes:attrs)
            attributedString.appendAttributedString(frozenAttributedString)
            text = nil
            attributedText = attributedString
        } else if isAttributedStringNeed {
            let mutableAttributedString = attributedText.mutableCopy() as! NSMutableAttributedString
            let attrs = [NSFontAttributeName :stroredTextFont ?? defaultTextFont, NSForegroundColorAttributeName: stroredTextColor ?? defaultTextColor, NSParagraphStyleAttributeName : paragraphStyle]
            let rangeOfNonFrozenText = NSMakeRange(frozenText.characters.count, mutableAttributedString.string.characters.count - frozenText.characters.count)
            mutableAttributedString.addAttributes(attrs, range: rangeOfNonFrozenText)
            attributedText = mutableAttributedString
        }
    }
    
    //MARK: Check or external delegate is present and responds to selector
    
    private func isExternalTextViewDelegateRespondsToSelector(selector: Selector) ->Bool {
        guard let extDelegate = externalTextViewDelegate else { return false}
        
        return extDelegate.respondsToSelector(selector)
    }
    
}


//MARK: UITextViewDelegate

extension FLTextView: UITextViewDelegate {
    
    public func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        guard let frozenText = frozenPrefix where textView != placeholderView else {
            return isExternalTextViewDelegateRespondsToSelector("textView:shouldChangeTextInRange:replacementText:") ? externalTextViewDelegate!.textView!(textView, shouldChangeTextInRange: range, replacementText: text) : true
        }
        
        let protectedRange = NSMakeRange(0, frozenText.characters.count)
        let intersection = NSIntersectionRange(protectedRange, range)
        
        let isDeletedSymbol = range.length == 1 && text == ""
        let shouldClearFrozenText = isDeletedSymbol && (textView.text.characters.count == frozenText.characters.count + 1) && intersection.location == 0 && intersection.length == 0
        
        if shouldClearFrozenText {
            textView.text = text
            return true
        }
        
        if textView.text.characters.count == 0 && frozenPrefix != nil && text != "" {
            textView.text = frozenPrefix
            applyStylesForFrozenText()
            return true
        }
        
        if intersection.length > 0 || intersection.location > 0 {
            
            return false
        }
        
        return isExternalTextViewDelegateRespondsToSelector("textView:shouldChangeTextInRange:replacementText:") ? externalTextViewDelegate!.textView!(textView, shouldChangeTextInRange: range, replacementText: text) : true
    }
    
    public func textViewDidChange(textView: UITextView) {
        applyStylesForFrozenText()
        showPlaceholderViewIfNeeded()
        if isExternalTextViewDelegateRespondsToSelector("textViewDidChange:") {
            externalTextViewDelegate!.textViewDidChange!(textView)
        }
    }
    
    public func textViewShouldBeginEditing(textView: UITextView) -> Bool {
        guard isExternalTextViewDelegateRespondsToSelector("textViewShouldBeginEditing:") else { return true}
        return externalTextViewDelegate!.textViewShouldBeginEditing!(textView)
    }
    
    public func textViewShouldEndEditing(textView: UITextView) -> Bool {
        guard isExternalTextViewDelegateRespondsToSelector("textViewShouldEndEditing:") else { return true }
        return externalTextViewDelegate!.textViewShouldEndEditing!(textView)
    }
    
    public func textViewDidBeginEditing(textView: UITextView) {
        guard isExternalTextViewDelegateRespondsToSelector("textViewDidBeginEditing:") else { return }
        externalTextViewDelegate!.textViewDidBeginEditing!(textView)
    }
    
    public func textViewDidEndEditing(textView: UITextView) {
        guard isExternalTextViewDelegateRespondsToSelector("textViewDidEndEditing:") else { return }
        externalTextViewDelegate!.textViewDidEndEditing!(textView)
    }
    
    public func textViewDidChangeSelection(textView: UITextView) {
        guard isExternalTextViewDelegateRespondsToSelector("textViewDidChangeSelection:") else { return }
        externalTextViewDelegate!.textViewDidChangeSelection!(textView)
    }
    
    public func textView(textView: UITextView, shouldInteractWithURL URL: NSURL, inRange characterRange: NSRange) -> Bool {
        guard isExternalTextViewDelegateRespondsToSelector("textView:shouldInteractWithURL:inRange:") else { return true }
        return externalTextViewDelegate!.textView!(textView, shouldInteractWithURL: URL, inRange: characterRange)
    }
    
    public func textView(textView: UITextView, shouldInteractWithTextAttachment textAttachment: NSTextAttachment, inRange characterRange: NSRange) -> Bool {
        guard isExternalTextViewDelegateRespondsToSelector("textView:shouldInteractWithTextAttachment:inRange:") else { return true }
        return externalTextViewDelegate!.textView!(textView, shouldInteractWithTextAttachment: textAttachment, inRange: characterRange)
    }
    
}
