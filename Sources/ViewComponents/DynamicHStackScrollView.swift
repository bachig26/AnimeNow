//
//  File.swift
//  
//
//  Created by ErrorErrorError on 2/9/23.
//  
//

import SwiftUI

public struct DynamicHStackScrollView<T: Identifiable, C: RandomAccessCollection<T>, V: View, L: View>: View where C.Index == Int {
    private let items: C
    private let itemContent: (T) -> V
    private let label: (() -> L)?

    private let idealWidth: CGFloat
    private let spacing: CGFloat

    #if os(macOS)
    @State private var visibleRange: Range<Int> = 0..<0
    @State private var actualWidth: CGFloat = 0.0
    #endif

    public init(
        idealWidth: CGFloat,
        spacing: CGFloat = 12,
        items: C,
        itemContent: @escaping (T) -> V,
        label: (() -> L)? = nil
    ) {
        self.idealWidth = idealWidth
        self.spacing = spacing
        self.items = items
        self.itemContent = itemContent
        self.label = label
    }

    public var body: some View {
        LazyVStack(alignment: .leading) {
            label?()
                .padding(.horizontal)
            #if os(macOS)
                .padding(.horizontal, 40)
            #endif
            container
            #if os(macOS)
                .arrowIndicators($visibleRange, items.bounds, shiftBy: 1)
            #endif
        }
        .frame(maxWidth: .infinity)
    }
}

extension DynamicHStackScrollView {
    public init(
        idealWidth: CGFloat,
        spacing: CGFloat = 12,
        items: C,
        itemContent: @escaping (T) -> V
    ) where L == EmptyView {
        self.init(
            idealWidth: idealWidth,
            spacing: spacing,
            items: items,
            itemContent: itemContent,
            label: nil
        )
    }
}

#if os(iOS)
extension DynamicHStackScrollView {
    @ViewBuilder
    var container: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: spacing) {
                ForEach(items, id: \.id) {
                    itemContent($0)
                        .frame(width: idealWidth)
                }
            }
            .padding(.horizontal)
        }
    }
}
#elseif os(macOS)
extension DynamicHStackScrollView {
    @ViewBuilder
    var container: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: spacing) {
                ForEach(items[visibleRange], id: \.id) {
                    itemContent($0)
                        .frame(width: max(0, actualWidth))
                }
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .leading
            )
        }
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        recalculate(proxy)
                    }
                    .onChange(of: idealWidth) { _ in
                        recalculate(proxy)
                    }
                    .onChange(of: spacing) { _ in
                        recalculate(proxy)
                    }
                    .onChange(of: proxy.size) { newValue in
                        recalculate(proxy)
                    }
                    .onChange(of: items.count) { newValue in
                        recalculate(proxy)
                    }
            }
        )
    }

    private func recalculateVisibleRange(_ maxItems: Int) {
        if visibleRange.count != items.bounds.prefix(maxItems).count {
            if items.bounds.contains(visibleRange.lowerBound) {
                // Okay, safe to reuse visibleRange's lower bounds
                let itemsRemaining = items.bounds[visibleRange.lowerBound...]

                if itemsRemaining.count < maxItems {
                    visibleRange = items.bounds[..<itemsRemaining.upperBound].suffix(maxItems)
                } else {
                    visibleRange = visibleRange.lowerBound..<itemsRemaining.prefix(maxItems).upperBound
                }
            } else {
                visibleRange = items.bounds.prefix(maxItems)
            }
        }
    }

    private func recalculate(_ proxy: GeometryProxy) {
        let maxFittingItems = round(proxy.size.width / idealWidth)
        let widthRemaining = proxy.size.width - (idealWidth * maxFittingItems)
        let totalSpacing = maxFittingItems * spacing
        let actualWidthRemainingPerItem = (widthRemaining - totalSpacing) / maxFittingItems
        actualWidth = actualWidthRemainingPerItem + idealWidth
        recalculateVisibleRange(Int(maxFittingItems))
    }
}

extension RandomAccessCollection {
    var bounds: Range<Self.Index> {
        startIndex..<endIndex
    }
}

#endif
