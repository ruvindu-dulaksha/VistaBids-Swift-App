import XCTest
@testable import VistaBids

final class CommentFunctionalityTests: XCTestCase {
    
    var communityService: CommunityService!
    
    override func setUp() {
        super.setUp()
        communityService = CommunityService()
    }
    
    override func tearDown() {
        communityService = nil
        super.tearDown()
    }
    
    func testCommentAddingAndRetrieval() async {
        // Test post ID - using one of the sample posts
        let postId = "1"
        
        // Get initial comments
        let initialComments = await communityService.getComments(for: postId)
        let initialCount = initialComments.count
        
        // Add a test comment
        let testCommentContent = "This is a test comment from unit tests \(UUID().uuidString)"
        await communityService.addComment(to: postId, content: testCommentContent)
        
        // Get updated comments
        let updatedComments = await communityService.getComments(for: postId)
        
        // Verify the comment was added
        XCTAssertEqual(updatedComments.count, initialCount + 1, "Comment count should increase by 1")
        
        // Try to find our test comment
        let foundComment = updatedComments.first { $0.content == testCommentContent }
        XCTAssertNotNil(foundComment, "The test comment should be found in the comments")
    }
}
