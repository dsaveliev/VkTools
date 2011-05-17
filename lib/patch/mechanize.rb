class Mechanize
  class CookieJar
   
    def dump_cookies
      result = ""
      to_a.each do |cookie|
        fields = []
        fields[0] = cookie.domain

        if cookie.domain =~ /^\./
          fields[1] = "TRUE"
        else
          fields[1] = "FALSE"
        end

        fields[2] = cookie.path

        if cookie.secure == true
          fields[3] = "TRUE"
        else
          fields[3] = "FALSE"
        end

        fields[4] = cookie.expires.to_i.to_s

        fields[5] = cookie.name
        fields[6] = cookie.value
        result << fields.join("\t") + "\n"
      end
      result
    end
    
    def load_cookies(text)
      now = Time.now
      fakeuri = Struct.new(:host)    # add_cookie wants something resembling a URI.

      text.each_line do |line|
        line.chomp!
        line.gsub!(/#.+/, '')
        fields = line.split("\t")

        next if fields.length != 7

        expires_seconds = fields[4].to_i
        begin
          expires = (expires_seconds == 0) ? nil : Time.at(expires_seconds)
        rescue
          next
          # Just in case we ever decide to support DateTime...
          # expires = DateTime.new(1970,1,1) + ((expires_seconds + 1) / (60*60*24.0))
        end
        next if (expires_seconds != 0) && (expires < now)

        c = Mechanize::Cookie.new(fields[5], fields[6])
        c.domain = fields[0]
        # Field 1 indicates whether the cookie can be read by other machines at the same domain.
        # This is computed by the cookie implementation, based on the domain value.
        c.path = fields[2]               # Path for which the cookie is relevant
        c.secure = (fields[3] == "TRUE") # Requires a secure connection
        c.expires = expires             # Time the cookie expires.
        c.version = 0                   # Conforms to Netscape cookie spec.

        add(fakeuri.new(c.domain), c)
      end
      @jar
    end
  end
end
