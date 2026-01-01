//
//  TMDBConfig.swift
//  CineSense
//
//  Created by Neel Joshi on 12/31/25.
//

import Foundation

enum TMDBConfig {
    static let apiKey = Bundle.main.object(forInfoDictionaryKey: "TMDB_API_KEY") as! String
    static let readAccessToken = Bundle.main.object(forInfoDictionaryKey: "TMDB_READ_ACCESS_KEY") as! String
    static let imageBaseURL = "https://image.tmdb.org/t/p/"
}
