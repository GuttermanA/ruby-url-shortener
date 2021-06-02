# Intial Setup

    docker-compose build
    docker-compose up mariadb
    # Once mariadb says it's ready for connections, you can use ctrl + c to stop it
    docker-compose run short-app rails db:migrate
    docker-compose -f docker-compose-test.yml build

# To run migrations

    docker-compose run short-app rails db:migrate
    docker-compose -f docker-compose-test.yml run short-app-rspec rails db:test:prepare

# To run the specs

    docker-compose -f docker-compose-test.yml run short-app-rspec

# Run the web server

    docker-compose up

# Adding a URL

    curl -X POST -d "full_url=https://google.com" http://localhost:3000/short_urls.json

# Getting the top 100

    curl localhost:3000

# Checking your short URL redirect

    curl -I localhost:3000/abc

# URL Shortening Algorithm

The algorithm used to produce the short code for the provided full URLs is the encoding the numeric database ID and the full url string into base62 encoding, taking the first 6 chars of the encoded full url string, and deriving the final shortcode by appending the encoded database id to the 6 char encoded full url string. The first 6 chars of the encoded full URL were chosen as it represents 56.8 billion (62^6) unique character combinations, which seemed adequate for the requirements of this application.

---

**NOTE**

I included an encoded form of the full url as I feel that deriving data from a arbitrary incrementing database id is bad practice for the long term data integrity of the application. For example, if it was determined that numeric ids were no longer adequate for such a system and there was a move over to something more robust like UUID, the base data for the encoding of the URL could be lost. When encoding data, I believe that the result of the encoding should always include at least a part of the decoded data

---

To encode a url string, first it must be converted into an integer with the following steps:

1. Convert each char in the string to bytes

2. Convert the collection of bytes into a hexadecimal

3. Convert the hexadecimal into an integer

These steps are achieved using the ruby unpack method to convert the string directly into a hexadecimal string. Then using the .to_i(16), the 16 representing the base 16 system for hexadecimal. The resulting integer is then ready to be fed into the base62 encoding algorithm described below.

Base62 encoding using all alphanumeric characters with lower- and upper-case letters was chosen as the encoding method. This method is both straightforward, lightweight, and URL safe given the main requirements of this application:

1. The short code is the shortest possible length relative to the number of links saved in the DB

2. The short code is unique

Given a positive integer, the short code algorithm will initialize an empty string to store the short code and a while loop:

1. Take the remainder of the current integer % 62(N characters or BASE) and find the corresponding char in the array of CHARACTERS

2. Prepend the found char to the short code string

3. Set the next number to be encoded as the current number / BASE

4. Terminate if the next number is 0 or less, as those values are not valid indices in our encoding array

If given a negative integer, the encoding method will return `ruby nil` indicating an invalid argument. If given 0, it will return the first element of the CHARACTERS array since the algorithm will always return that value given 0.

## Possible Improvements

Given the requirements of the for the shortcode to be "shortest possible length relative to the number of links" in the db, I chose to append the encoding ID to the end of the string. This method has 1 significant weakness: As the number of links in the database increases, the length of the shortcode will also increase, decreasing db efficiency and eventually defeat the purpose of the shortcode and make it too long.

To mitigate this issue, we can set a constant length for the shortcode, like 7 characters. This would give us 3.5 trillion (62^7) possible character combinations, more than enough for a URL shortening application. If we wanted the system to be even more robust and to maintain the involvement of the database ID in deriving the shortcode, we could concatenate the integer derived from the full url and the integer id before it is fed to the encoding algorithm, making the last several digits of each integer that is ready to be encoded completely unique.

Alternatively, it's possible that the solution presented is too robust for the given requirements. Theoretically, the shortcode could exclusively be derived from the database ID. In this case, the application no longer needs to worry about the uniqueness of the short code as it will always be unique since the database ids will be unique. The short code will always be short without having to chop characters off the encoding, as the given base62 encoding algorithm will encode a 1 trillion integer into only 7 characters. Going down this route also allows does not require the shortcode to be persisted in the database since the algorithm encoding algorithm is lightweight, saving on disk space in case that was an additional consideration of this application.
