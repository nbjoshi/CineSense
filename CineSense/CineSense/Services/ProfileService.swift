//
//  ProfileService.swift
//  CineSense
//
//  Created by Neel Joshi on 1/3/26.
//

import Foundation
import Supabase
import SwiftUI

final class ProfileService {
    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseClientProvider.shared.client) {
        self.client = client
    }
    
    func uploadAvatarUrl(image: UIImage) async throws -> Void {}
    
    func changeProfileDetails(displayName: String, bio: String, isPublic: Bool) { }
}
