table 80015 "PC Shopify Order Exceptions"
{
    DataClassification = ToBeClassified;
    
    fields
    {
        field(10;ID; Integer)
        {
            AutoIncrement = True;
        }
        field(20;"ShopifyID";BigInteger)
        {
        }
        field(30;"Exception";Text[150])
        {
        }
      
    }
  
    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
    }
    
}