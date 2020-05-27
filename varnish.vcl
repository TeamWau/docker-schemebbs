vcl 4.1;

backend default
{
	.host = "sbbs";
	.port = "8080";

	.first_byte_timeout = 30s;
	.connect_timeout = 5s;
	.between_bytes_timeout = 2s;
}

sub vcl_backend_response
{
	set beresp.http.X-Clacks-Overhead = "GNU John McCarthy";

	if (bereq.uncacheable)
	{
		return (deliver);
	}
	else if (beresp.status >= 500)
	{	 
		return (abandon);
	}
	else if (beresp.ttl <= 0s)
	{
		set beresp.ttl = 120s;
		set beresp.uncacheable = true;
	}
	else
	{
		set beresp.grace = 3h;
	}
	return (deliver);
}
