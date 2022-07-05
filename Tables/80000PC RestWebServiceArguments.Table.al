table 80000 "PC RestWebServiceArguments"
{

    fields
    {
        field(10; PrimaryKey; Integer) { }
        field(20; RestMethod; Option)
        {
            OptionMembers = GET,POST,DELETE,PATCH,PUT;
        }
        field(30; URL; Text[2048]) { }
        field(40; Accept; Text[30]) { }
        field(50; ETag; Text[250]) { }
        Field(60; "Access Token"; text[150]) { }
        field(65; "SPS Access Token 1"; text[1000]){}
        field(66; "SPS Access Token 2"; text[200]) {}
        Field(70; "Token Type"; Option) 
        { 
            OptionMembers = Shopify,FulFilio,SpsAuth,SpsData;
        }
        field(100; Blob; Blob) { }
    }
    keys
    {
        key(PK; PrimaryKey)
        {
            Clustered = true;
        }
    }

    var
        RequestContent: HttpContent;
        RequestContentSet: Boolean;
        ResponseHeaders: HttpHeaders;

    procedure SetRequestContent(var value: HttpContent)
    begin
        RequestContent := value;
        RequestContentSet := true;
    end;

    procedure HasRequestContent(): Boolean
    begin
        exit(RequestContentSet);
    end;

    procedure GetRequestContent(var value: HttpContent)
    begin
        value := RequestContent;
    end;

    procedure SetResponseContent(var value: HttpContent)
    var
        InStr: InStream;
        OutStr: OutStream;
    begin
        Blob.CreateInStream(InStr);
        value.ReadAs(InStr);

        Blob.CreateOutStream(OutStr);
        CopyStream(OutStr, InStr);
    end;

    procedure HasResponseContent(): Boolean
    begin
        exit(Blob.HasValue);
    end;

    procedure GetResponseContent(var value: HttpContent)
    var
        InStr: InStream;
    begin
        Blob.CreateInStream(InStr);
        value.Clear();
        value.WriteFrom(InStr);
    end;

    procedure GetResponseContentAsText() ReturnValue: text
    var
        InStr: InStream;
        Line: text;
    begin
        if not HasResponseContent then
            exit;

        Blob.CreateInStream(InStr);
        InStr.ReadText(ReturnValue);

        while not InStr.EOS do begin
            InStr.ReadText(Line);
            ReturnValue += Line;
        end;
    end;

    procedure SetResponseHeaders(var value: HttpHeaders)
    begin
        ResponseHeaders := value;
    end;

    procedure GetResponseHeaders(var value: HttpHeaders)
    begin
        value := ResponseHeaders;
    end;

}