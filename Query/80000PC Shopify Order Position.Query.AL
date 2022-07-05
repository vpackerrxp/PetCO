/*query 80000 "PC Shopify Order Position"
{
    QueryType = Normal;
    
    elements
    {
        dataitem(DataItemName; "PC Shopify Order Header")
        {
            column(OrderID; "Shopify Order ID")
            {
               Method = Max; 
            }
        }    
    }
} */