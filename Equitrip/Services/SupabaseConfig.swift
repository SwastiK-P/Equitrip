//
//  SupabaseConfig.swift
//  Equitrip
//

import Foundation

/// Project connection details.
///
/// The publishable key is designed to ship inside the client — it grants no
/// privileges on its own. Every table must therefore have Row Level Security
/// enabled, or this key can read it. Never put the `service_role` /
/// secret key in the app.
enum SupabaseConfig {
    static let url = URL(string: "https://dfuxvvatgtxpbzvosgaw.supabase.co")!
    static let publishableKey = "sb_publishable_23IfOXEjCyDcl2N5WDqwWQ_87Y0vZM9"
}
