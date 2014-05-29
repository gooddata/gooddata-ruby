# Rest

Proof of Concept of GoodWay of dealing with non-perfect REST Endpoints

## Terminology

Terms like 'MUST', 'MUST NOT', 'SHALL', 'SHALL NOT' are used as defined in [RFC 2119](https://www.ietf.org/rfc/rfc2119.txt)

## Architecture

There are few basic classes.

- Connection
- Client
- Factory
- Object
- Resource

## Connection

Low-level network connection

## Client

User's interface to GoodData Platform.

## Factory

Authority responsible for creating Object bounded to some Connection.

## Object

Remote REST-like accessible content.

## Resource

Objects which are (at least mimicking to be) first class citizen REST Resource with full CRUD