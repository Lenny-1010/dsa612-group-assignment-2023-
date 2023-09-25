import ballerina/grpc;
import ballerina/log;
import ballerina/io;

type BookRecord record {
    string isbn;
    string title;
    string author_1;
    string author_2;
    string location;
    boolean available;
};

map<BookRecord> books = {};

service LibraryService on new grpc:Listener(9090) {

    resource function addBook(grpc:Caller caller, library:Book request) returns string {
    //Generate a unique ISBN (e.g., using a UUID or a custom generator)
    string generatedIsbn = generateUniqueIsbn();
    
    //Add the book to the library with the generated ISBN
    library.isbn = generatedIsbn;
    books[generatedIsbn] = request;

    //Log the book addition
    log:info("Added book with ISBN: " + generatedIsbn);

    //Return the generated ISBN
    return generatedIsbn;
}

function generateUniqueIsbn() returns string {
    //Generate a unique ISBN 
    return "ISBN-" + uuid:genRandomUUID().toString();
}

    resource function createUsers(stream<library:User> userStream) returns library:User {
    //Initialize an empty variable to store the last user created
    library:User lastUser = ();

    //Process incoming user stream
    var user;
    while (userStream.hasNext()) {
        user = userStream.getNext();
        
        //Set the last user created
        lastUser = user;
        
        //Log user creation
        log:info("Created user with ID: " + user.user_id + " and type: " + user.user_type);
    }

    //Return the last user created
    return lastUser;
    }


    resource function updateBook(library:Book request) returns library:Book {
        resource function updateBook(library:Book request) returns library:Book {
    //Check if the book with the given ISBN exists
    if (books.containsKey(request.isbn)) {
        //Get the existing book
        var existingBook = books[request.isbn];

        //Update the book details with the new values
        existingBook.title = request.title;
        existingBook.author_1 = request.author_1;
        existingBook.author_2 = request.author_2;
        existingBook.location = request.location;
        existingBook.available = request.available;

        //Log the book update
        log:info("Updated book with ISBN: " + existingBook.isbn);

        //Return the updated book details
        return existingBook;
    } else {
        //Book not found, return an empty book with an error message
        library.Book notFoundBook = { isbn: "", title: "Book not found", author_1: "", author_2: "", location: "", available: false };
        return notFoundBook;
    }
}

    resource function removeBook(string isbn) returns library.Book[] {
    //Check if the book with the given ISBN exists
    if (books.containsKey(isbn)) {
        //Remove the book from the library
        var removedBook = books.remove(isbn);

        //Log the book removal
        log:info("Removed book with ISBN: " + removedBook.isbn);

        //Return the updated list of books (excluding the removed book)
        library.Book[] updatedBooks = books.values();
        return updatedBooks;
    } else {
        //Book not found, return the current list of books as is
        library.Book[] currentBooks = books.values();
        return currentBooks;
    }
}

    resource function listAvailableBooks(library:User user) returns stream<library.Book> {
    //Initialize an empty stream to send available books
    stream<library.Book> availableBooksStream = new;

    //Filter books based on user type
    library.Book[] availableBooks = filterBooksByUserType(user);

    //Send available books one by one to the client
    foreach var book in availableBooks {
        check availableBooksStream->push(book);
    }

    //Return the stream of available books
    return availableBooksStream;
}

function filterBooksByUserType(library:User user) returns library.Book[] {
    //Filter available books based on user type
    library.Book[] filteredBooks = [];

    //Iterate through all books and filter by user type
    foreach var book in books.values() {
        //For student, show all available books
        if (user.user_type == "student" && book.available) {
            filteredBooks.push(book);
        }
        //For librarian, show all books, whether available or not
        else if (user.user_type == "librarian") {
            filteredBooks.push(book);
        }
    }

    return filteredBooks;
}

    resource function locateBook(string isbn) returns string {
    //Check if the book with the given ISBN exists
    if (books.containsKey(isbn)) {
        //Get the book's location
        string location = books[isbn].location;

        //Log the book location
        log:info("Located book with ISBN " + isbn + " at " + location);

        //Return the book's location
        return location;
    } else {
        //Book not found, return an error message
        log:info("Book with ISBN " + isbn + " not found");
        return "Book not found";
    }
}

    resource function borrowBook(library:User user) returns string {
    //Check if the user is a student and has provided a valid ISBN
    if (user.user_type == "student" && user.user_id > 0 && user.user_id <= 1000) {
        //Get the student's user ID and ISBN from the user object
        int studentId = user.user_id;
        string isbnToBorrow = generateIsbnToBorrow(studentId);

        //Check if the book with the given ISBN exists and is available
        if (books.containsKey(isbnToBorrow) && books[isbnToBorrow].available) {
            // Mark the book as unavailable
            books[isbnToBorrow].available = false;

            //Log the book borrowing
            log:info("Student with ID: " + studentId + " borrowed book with ISBN: " + isbnToBorrow);

            //Return a success message
            return "Book with ISBN " + isbnToBorrow + " has been borrowed successfully.";
        } else {
            //Book not found or not available, return an error message
            return "Book not found or not available for borrowing.";
        }
    } else {
        //Invalid user or user type, return an error message
        return "Invalid user type or user ID.";
    }
}

function generateIsbnToBorrow(int studentId) returns string {
    // Generate a unique ISBN for the student's borrowed book
    return "BORROWED-" + studentId;
}

}