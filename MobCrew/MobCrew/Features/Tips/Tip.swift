import Foundation

struct Tip: Identifiable {
    let id = UUID()
    let title: String
    let body: String
    let author: String
    
    static let allTips: [Tip] = [
        Tip(
            title: "Driver/Navigator Pattern",
            body: "For an idea to go from your head into the computer it MUST go through someone else's hands.",
            author: "Llewellyn Falco"
        ),
        Tip(
            title: "Trust Your Navigator",
            body: "The right time to discuss and challenge design decisions is after the solution is out of the navigator's head.",
            author: "Llewellyn Falco"
        ),
        Tip(
            title: "Driving With An Idea",
            body: "What if I have an idea I want to implement? Great! Switch places and become the navigator.",
            author: "Llewellyn Falco"
        ),
        Tip(
            title: "Mob Decision-Making",
            body: "Arguing about solutions? Try going with the least experienced navigator and have the more experienced team members course correct only as needed.",
            author: "The Hunter Mob"
        ),
        Tip(
            title: "Lean Thinking",
            body: "The goal is not to be productive but effective. Being productive and not effective is usually a good way to produce waste quickly.",
            author: "Woody Zuill"
        ),
        Tip(
            title: "Mob Programming",
            body: "It's not about Mob Programming. It's about discovering the principles and practices that are important in the context of the work you are doing.",
            author: "Woody Zuill"
        ),
        Tip(
            title: "Shared Attention",
            body: "With everyone paying attention pretty often, we stay focused, never stay stuck for long, and make better choices.",
            author: "Amitai Schleier"
        ),
        Tip(
            title: "Limit WIP",
            body: "Since there's no \"my bugfix\" or \"your feature\", we naturally limit our Work In Progress.",
            author: "Amitai Schleier"
        ),
        Tip(
            title: "Individuals Over Processes",
            body: "We have come to value individuals and interactions over processes and tools.",
            author: "Agile Manifesto"
        ),
        Tip(
            title: "Working Software",
            body: "Working software is the primary measure of progress.",
            author: "Agile Manifesto"
        ),
        Tip(
            title: "Sustainable Pace",
            body: "Agile processes promote sustainable development. The sponsors, developers, and users should be able to maintain a constant pace indefinitely.",
            author: "Agile Manifesto"
        ),
        Tip(
            title: "Simplicity",
            body: "Simplicity—the art of maximizing the amount of work not done—is essential.",
            author: "Agile Manifesto"
        )
    ]
    
    static func random() -> Tip {
        allTips.randomElement() ?? allTips[0]
    }
}
