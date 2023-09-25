import ballerina/grpc;
import ballerina/io;

function main() {
    //Create a gRPC client for the LibraryService
    grpc:Client libraryClient = new grpc:Client("http://localhost:9090", library.LibraryService);

    //Create a User (student or librarian)
    library.User user = {user_id: 123, user_type: "student"};

    //Add a book
    library.Book bookToAdd = {
        isbn: "978-1234567890",
        title: "Sample Book",
        author_1: "John Doe",
        author_2: "Jane Doe",
        location: "Shelf A",
        available: true
    };
    string addedIsbn = check libraryClient->addBook(bookToAdd);
    io:println("Added book with ISBN: " + addedIsbn);

    //List available books
    stream<library.Book> availableBooksStream = check libraryClient->listAvailableBooks(user);
    while (availableBooksStream.hasNext()) {
        library.Book availableBook = check availableBooksStream.getNext();
        io:println("Available Book: " + availableBook.title);
    }

    //Locate a book
    string isbnToLocate = "978-1234567890";
    string location = check libraryClient->locateBook(isbnToLocate);
    if (location != "") {
        io:println("Book is located at: " + location);
    } else {
        io:println("Book is not available.");
    }

    //Borrow a book
    string borrowStatus = check libraryClient->borrowBook(user);
    io:println(borrowStatus);

    //Close the gRPC client
    check libraryClient.stop();
}