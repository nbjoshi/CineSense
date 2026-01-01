//
//  SupabaseConfig.swift
//  CineSense
//
//  Created by Neel Joshi on 12/31/25.
//

import Foundation

enum SupabaseConfig {
    static let url = URL(string: Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as! String)!
    static let anonKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as! String
}
