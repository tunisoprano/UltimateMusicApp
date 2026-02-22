//
//  JamWidgetBundle.swift
//  2JamWidget
//
//  Widget Bundle - Entry point for all widgets
//

import WidgetKit
import SwiftUI

@main
struct JamWidgetBundle: WidgetBundle {
    var body: some Widget {
        TunerWidget()
        MetronomeWidget()
    }
}
