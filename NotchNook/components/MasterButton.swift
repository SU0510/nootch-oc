//
//  MasterButton.swift
//  damage
//
//  Created by Igor Marcossi on 01/05/23.
//

import SwiftUI

let BTN_SHRINK_ANIMATION = Animation.spring(response: 0.35)

enum MasterButtonMode {
		case soft
		case normal
		case subtle
}

enum ColorHoverEffect {
		case none
		case normal
		case animated
}

enum ProportionalTypes {
		case no
		case circle
		case yes
}

struct MasterButton: View {
		var icon: String? = nil
		var label: String? = nil
		var mode: MasterButtonMode = .normal
		var color: Color = .blue
		var colorHoverEffect: ColorHoverEffect = .normal
		var textColor: Color = .white
		var shrinkHoverEffect: Bool = false
		var padding: CGFloat = 10
		var height: CGFloat = 36
		var fullWidth: Bool = false
		var align: Alignment = .center
		var fullHeight: Bool = false
		var cornerRadius: CGFloat = 10
		var shrinkRatio: CGFloat = 0.0175
		var confirmLabel: String? = nil
		var proportional: ProportionalTypes = .no
		var growAnchor: Alignment = .center
		var fontSize: CGFloat = 13
		var disabled = false
		var hoverWorkaround = false
		let action: () -> Void
		
		@State var initialSize = CGSize.zero
		@State var confirming = false
		@State var pressing = false
		@State var hovering = false
		
		var body: some View {
				let btnCornerRadius = proportional == .circle ? height / 2 : cornerRadius
				let isHovering = !disabled && (colorHoverEffect != .none || shrinkHoverEffect ? hovering : false)
				let finalColor = color.opacity(mode == .normal ? 1 : mode == .subtle ? isHovering ? 0.1 : 0 : 0.2 )
				let proportionalSize = proportional != .no ? height : nil
				Button {
						if confirmLabel != nil {
								if confirming {
										action()
								} else {
										withAnimation(BTN_SHRINK_ANIMATION) {
												confirming = true
										}
								}
						} else {
								action()
						}
				} label: {
						HStack {
								if let icon = icon {
										Image(systemName: icon)
												.transition(.scaleAndBlur)
												.id(icon)
								}
								Group {
										if let label = label {
												Text(confirming ? confirmLabel ?? label : label)
														.fixedSize(horizontal: true, vertical: false)
														.id(confirming ? confirmLabel : label)
										} else if let confirmLabel = confirmLabel, confirming {
												Text(confirmLabel)
														.font(Font(NSFont.systemFont(ofSize: 11, weight: .medium)))
														.id(confirmLabel)
										}
								}
								.transition(.scaleAndBlur)
						}
						.font(Font(NSFont.systemFont(ofSize: fontSize, weight: .medium)))
//						.padding(.vertical, padding)
						.padding(.horizontal, 10 * 1.5)
						.foregroundColor(textColor)
						.frame(maxWidth: fullWidth ? .infinity : nil, maxHeight: fullHeight ? .infinity : height, alignment: align)
						.frame(width: confirming ? nil : proportionalSize, height: fullHeight ? nil : height)
						.background(
								RR(btnCornerRadius, finalColor)
										.brightness(colorHoverEffect != .none ? pressing ? -0.1 : isHovering ? 0.1 : 0 : 0)
						)
						.mask(
								RR(btnCornerRadius, .white)
						)
						.scaleEffect(1 + (shrinkHoverEffect ? pressing ? -shrinkRatio : isHovering ? shrinkRatio : 0 : 0) )
//						.if(hoverWorkaround) { v in
//								v.contentShape(RoundedRectangle(cornerRadius: btnCornerRadius, style: .continuous))
//						}
						.onHover { val in
								if shrinkHoverEffect || colorHoverEffect == .animated {
										withAnimation(BTN_SHRINK_ANIMATION) {
												hovering = val
										}
								} else {
										hovering = val
								}
						}
//						.if(!hoverWorkaround) { v in
//								v.contentShape(RoundedRectangle(cornerRadius: btnCornerRadius, style: .continuous))
//						}
				}
				.disabled(disabled)
				.saturation(disabled ? 0 : 1)
				.opacity(disabled ? 0.75 : 1)
				.fixedSize(horizontal: confirming, vertical: confirming)
                .measure($initialSize)
				.frame(maxWidth: fullWidth ? .infinity : confirming ? initialSize.width : nil, alignment: growAnchor)
				.buttonStyle(MasterBtnStyle(pressing: $pressing, animated: shrinkHoverEffect || colorHoverEffect == .animated, disable: !shrinkHoverEffect && colorHoverEffect == .none))
				.onChange(of: confirming) { newValue in
						if newValue {
								DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
										withAnimation(BTN_SHRINK_ANIMATION) {
												confirming = false
										}
								}
						}
				}
		}
}

struct MasterBtnStyle: ButtonStyle {
		@Binding var pressing: Bool
		var animated = false
		var disable = false
		func makeBody(configuration: Self.Configuration) -> some View {
				configuration.label
						.onChange(of: configuration.isPressed) { newValue in
								if disable { return }
								if animated {
										withAnimation(BTN_SHRINK_ANIMATION) {
												pressing = newValue
										}
								} else {
										pressing = newValue
								}
						}
		}
}
