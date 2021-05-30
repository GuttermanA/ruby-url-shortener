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

## Description

The algorithm used to produce the short code for the provided full URLs is the encoding of the numeric database ID into base 62 encoding. The character set used used for encoding are all alphanumeric characters with lower and uppder case letters.

`ruby
    CHARACTERS = [*"0".."9", *"a".."z", *"A".."Z"]
`

This method was chosen as it was the lightest weight solution given the requirements:

1. The short code is the shortest possible length relative to the number of links saved in the DB
2. The short code is unique

Given a positive integer ID, the algorithm will initialize an empty string to store the short code and a while loop:

1. Take the remainder of the current integer % 62(N characters or BASE) and find the corresponding char in the array of CHARACTERS
2. Prepend the found char to the short code string
3. Set the next number to be encoded as the current number / BASE
4. Terminate if the next number is 0 or less, as those values are not valid indices in our encoding array

## Other Methods

There are significant limitations to the algorithm chosen. If building a large scale application that would need to serve millions of users with significant numbers of concurrent requests and billions of unique URLs, this app will not be up to the task. If given additional time to work on this problem, it could be upgraded in the following ways:

1. Including an encoded portion of the full url in the short code -- Hashing the url using an existing methods, such as SHA256 and taking the first 6 chars of that URL and running them through the encoding method would result in a more robust short code that is also based off of the given URL rather than the arbitrary db ID
