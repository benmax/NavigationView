//
//  NavigationManager.swift of NavigationView
//
//  Created by Tomasz Kurylik
//    - Twitter: https://twitter.com/tkurylik
//    - Mail: tomasz.kurylik@mijick.com
//
//  Copyright ©2023 Mijick. Licensed under MIT License.


import SwiftUI

public class NavigationManager: ObservableObject {
    @Published private(set) var views: [AnyNavigatableView] = [] { willSet { onViewsWillUpdate(newValue) } }
    private(set) var transitionsBlocked: Bool = false { didSet { onTransitionsBlockedUpdate() } }
    private(set) var transitionType: TransitionType = .push
    private(set) var transitionAnimation: TransitionAnimation = .no
    private(set) var navigationBackGesture: NavigationBackGesture.Kind = .no

    static let shared: NavigationManager = .init()
    private init() {}
}

// MARK: - Operations Handler
extension NavigationManager {
    static func performOperation(_ operation: Operation) { if !NavigationManager.shared.transitionsBlocked {
        DispatchQueue.main.async { shared.views.perform(operation) }
    }}
}

// MARK: - Setters
extension NavigationManager {
    static func setRoot(_ rootView: some NavigatableView) { DispatchQueue.main.async { shared.views = [.init(rootView, .no)] }}
    static func replaceRoot(_ newRootView: some NavigatableView) { DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { shared.transitionType = .replaceRoot(.init(newRootView, .no)) }}
    static func blockTransitions(_ value: Bool) { shared.transitionsBlocked = value }
    static func setTransitionType(_ value: TransitionType) { if shared.transitionType != value { shared.transitionType = value }}
}

// MARK: - Gesture Handlers
extension NavigationManager {
    func gestureStarted() {
        transitionAnimation = views.last?.animation ?? .no
        navigationBackGesture = views.last?.configure(view: .init()).navigationBackGesture ?? .no
    }
}

// MARK: - On Attributes Will/Did Change
private extension NavigationManager {
    func onViewsWillUpdate(_ newValue: [AnyNavigatableView]) { if newValue.count != views.count {
        transitionType = newValue.count > views.count || !transitionType.isOne(of: .push, .pop) ? .push : .pop
        transitionAnimation = (transitionType == .push ? newValue.last?.animation : views[newValue.count].animation) ?? .no
        navigationBackGesture = newValue.last?.configure(view: .init()).navigationBackGesture ?? .no
    }}
    func onTransitionsBlockedUpdate() { if !transitionsBlocked, case let .replaceRoot(newRootView) = transitionType {
        views = views.appendingAsFirstAndRemovingDuplicates(newRootView)
    }}
}

// MARK: - Transition Type
extension NavigationManager { enum TransitionType: Equatable {
    case pop, push
    case replaceRoot(AnyNavigatableView)
}}

// MARK: - Array Operations
extension NavigationManager { enum Operation {
    case insert(any NavigatableView, TransitionAnimation)
    case removeLast, removeAll(toID: String), removeAllExceptFirst
}}
fileprivate extension [AnyNavigatableView] {
    mutating func perform(_ operation: NavigationManager.Operation) { if !NavigationManager.shared.transitionsBlocked {
        hideKeyboard()
        performOperation(operation)
    }}
}
private extension [AnyNavigatableView] {
    func hideKeyboard() {
        KeyboardManager.hideKeyboard()
    }
    mutating func performOperation(_ operation: NavigationManager.Operation) {
        switch operation {
            case .insert(let view, let animation): append(.init(view, animation), if: canBeInserted(view))
            case .removeLast: removeLastExceptFirst()
            case .removeAll(let id): removeLastTo(elementWhere: { $0.id == id })
            case .removeAllExceptFirst: removeAllExceptFirst()
        }
    }
}
private extension [AnyNavigatableView] {
    func canBeInserted(_ view: any NavigatableView) -> Bool { true }
}
