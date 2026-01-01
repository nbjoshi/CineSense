//
//  TMDBConfig.swift
//  CineSense
//
//  Created by Neel Joshi on 12/31/25.
//

import Foundation

enum TMDBConfig {
    static let apiKey = Bundle.main.object(forInfoDictionaryKey: "TMDB_API_KEY") as! String
    static let baseURL = URL(string: "https://api.themoviedb.org/3")!
    static let imageBaseURL = "https://image.tmdb.org/t/p/"
}
