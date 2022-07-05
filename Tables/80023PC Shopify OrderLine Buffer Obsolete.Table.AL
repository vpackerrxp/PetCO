table 80023 "PC Shopify OrderLine Buffer"
{
    ObsoleteState = Removed;    
    fields
    {
        field(10;ID; BigInteger)
        {
            AutoIncrement = true;
        }
        field(20;"ShopifyID";BigInteger)
        {
        }
        field(30;"Order Line ID";BigInteger)
        {
        }
        field(40;"Order Line No";Integer)
        {
        }
        field(50;"Shopify Order ID";BigInteger)
        {
        }
        field(60;"Item No."; Code[20])
        {
        }
        field(70;"Order Qty";Decimal)
        {
        }
        field(80;"Unit Price";Decimal)
        {
        }
        field(90;"Base Amount";Decimal)
        {
        }
        field(100;"Tax Amount";Decimal)
        {
        }
        field(110;"Discount Amount";Decimal)
        {
        }
 
    }
    keys
    {
        key(PK; ID)
        {
            Clustered = true;
        }
    }
}    