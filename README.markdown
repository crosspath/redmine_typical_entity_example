# Plugin Supply

An example of using [redmine_typical_entity](https://github.com/crosspath/redmine_typical_entity) to show, how to manipulate typical entity (model) in [Redmine](https://github.com/redmine/redmine).

## Description

Abstract:  
Store list of clients in Redmine with history of changes and notes about their orders.

The company deliveres equipment for photo and video shooting.
A user of Redmine creates clients' orders in Redmine.
Each order contains client's name, expected date of delivery, delivery address, sum and list of ordered products.
Then workers of the company collect and pack products and pass it to delivery service.
The process of acquisition of the order is reflected in the change of status of the order.
So, orders may be represented as issues in Redmine.
These issues should have additional fields: "Client", "Expected date of delivery", "Delivery address", "Sum", "Products".
Viewing history of clients' orders should be available at any time with filtering orders by client's name.

Model/Attribute | Type
---|---
Client | 
id | int, serial
name | string
notes | string
---|---
Product | 
id | int, serial
name | string
descr | string
image | Attachment
---|---
Issue | 
Client | Client
Expected date of delivery | date
Delivery address | string
Sum | string
Products | array<Product>
