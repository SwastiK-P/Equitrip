//
//  EquitripWidgetBundle.swift
//  EquitripWidgets
//

import SwiftUI
import WidgetKit

@main
struct EquitripWidgetBundle: WidgetBundle {
    var body: some Widget {
        BalanceWidget()
        TimelineWidget()
        AddExpenseControl()
        AskEquiControl()
    }
}
