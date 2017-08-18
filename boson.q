// BosonNLP 玻森中文语义平台 -- q接口
/ @see http://bosonnlp.com/
\d .boson

/ API URL
URL:"http://api.bosonnlp.com"

/ API request type
REQ_TYPE:"POST"

/ API request headers
REQ_HEADERS:("User-Agent";"Content-Type";"Accept")!(
    "KDB+/",string .z.K;
    "application/json";
    "application/json")

/ 情感分析
/ @see http://docs.bosonnlp.com/sentiment.html
/ @param token (String) BosonNLP API密钥
/ @param model (Symbol) {@literal `} if using the "general" model
/ @param strs (String List) string or list of strings to be analyzed (max 10 strings in one query)
/ @return (Real List) list of {@literal (non-negative, negative)} possibility pairs (each pair sums to 1)
Sentiment:{[token;model;strs]
    impl.extractResult
        impl.query[
            impl.buildHeader[
                token;
                "/sentiment/analysis";
                enlist[`general^model]!1#0N; ]
           ;$[10h=type strs;enlist strs;strs]]
    };

/ 命名实体识别
/ @see http://docs.bosonnlp.com/ner.html
/ @param token (String) BosonNLP API密钥
/ @param sensitivity (Int) 1 to 5 (default: 3)
/ @param strs (String List) string or list of strings to be analyzed (max 100 strings in one query)
/ @return (Table) columns: {@literal tag}, {@literal word} and {@literal entity} 
NER:{[token;sensitivity;strs]
    impl.extractResult
        impl.query[
            impl.buildHeader[
                token;
                "/ner/analysis";
                enlist[`sensitivity]!1#3; ]
           ;$[10h=type strs;enlist strs;strs]]
    };

/ 依存文法分析
/ @see http://docs.bosonnlp.com/depparser.html
/ @param token (String) BosonNLP API密钥
/ @param strs (String List) string or list of strings to be analyzed (max 100 strings in one query)
/ @return (Table) columns: {@literal head}, {@literal role}, {@literal tag} and {@literal word}
DepParser:{[token;strs]
    impl.extractResult
        impl.query[
            impl.buildHeader[
                token;
                "/depparser/analysis";
                ()!(); ]
           ;$[10h=type strs;enlist strs;strs]]
    };

/ 新闻分类
/ @see http://docs.bosonnlp.com/classify.html
/ @param token (String) BosonNLP API密钥
/ @param strs (String List) string or list of strings to be analyzed (max 100 strings in one query)
/ @return (Real List) news classification of each input string
Classify:{[token;strs]
    impl.extractResult
        impl.query[
            impl.buildHeader[
                token;
                "/classify/analysis";
                ()!(); ]
           ;$[10h=type strs;enlist strs;strs]]
    };

/ 语义联想
/ @see http://docs.bosonnlp.com/suggest.html
/ @param token (String) BosonNLP API密钥
/ @param params (Dict) additional query parameters
/ @param word (String) word to be analyzed
/ @return (List) list of {@literal (weight, word/type)} pairs
Suggest:{[token;params;word]
    impl.extractResult
        impl.query[
            impl.buildHeader[
                token;
                "/suggest/analysis";
                (1#`top_k)!(1#10); ]
           ;word]
    };

/ 关键词提取
/ @see http://docs.bosonnlp.com/keywords.html
/ @param token (String) BosonNLP API密钥
/ @param params (Dict) additional query parameters
/ @param str (String) string to be analyzed
/ @return (List) list of {@literal (weight, keyword)} pairs
Keywords:{[token;params;str]
    impl.extractResult
        impl.query[
            impl.buildHeader[
                token;
                "/keywords/analysis";
                (`segmented _`top_k`segmented!100 1),params; ]
           ;str]
    };
    
/ 分词与词性标注
/ @see http://docs.bosonnlp.com/tag.html
/ @param token (String) BosonNLP API密钥
/ @param params (Dict) additional query parameters
/ @param strs () string or strings to be analyzed
/ @return (Table) columns: {@literal tag} and {@literal word} 
Tag:{[token;params;strs]
    impl.extractResult
        impl.query[
            impl.buildHeader[
                token;
                "/tag/analysis";
                (`space_mode`oov_level`t2s`special_char_conv!0 3 0 0),params; ]
           ;$[10h=type strs;enlist strs;strs]]
        };

/ 时间转换
/ @see http://docs.bosonnlp.com/time.html
/ @param token (String) BosonNLP API密钥
/ @param pattern (String) time format sample pattern
/ @param basetime () a date or time or timestamp (null to use server GMT+8 local time)
/ @return (Dict) compulsory key: {@literal `type}
Time:{[token;pattern;basetime]
    impl.extractResult
        impl.query[
            impl.buildHeader[
                token;
                "/time/analysis";
                ((1#`pattern)!1#`$pattern),$[null basetime;()!();(1#`basetime)!1#`$string basetime]; ]
           ;::]
        };

/ 新闻摘要
/ @see http://docs.bosonnlp.com/summary.html
/ @param token (String) BosonNLP API密钥
/ @param pct (Real) if {@literal <= 0}, summarize to percentage of original text; else, summerize to {@code pct} characters
/ @param strict (Bool) if to strictly obey {@code pct} limit (may sacrifice quality of summary text)
/ @param title (String) title of the article
/ @param body (String) body text of the article (max 10000 characters)
/ @return (String) summary text
Summary:{[token;pct;strict;title;body]
    impl.extractResult
        impl.query[
            impl.buildHeader[
                token;
                "/summary/analysis";
                ()!(); ]
           ;`not_exceed`percentage`title`content!(strict+0;pct;title;body)]
    };

///////////////////////////////////////////////////////////////////////////////

/ Extract result from an HTTP response
impl.extractResult:{
    $[("I"$@[;1]" "vs first x:"\r\n"vs x)within 200 299;
        .j.k"\n"sv(1+first where 0=count each x)_x;
        'first x]
    };

/ Build HTTP request header
/ @param token (String) BosonNLP API密钥
/ @param path (String) API query path
/ @param params (Dict) API query parameters
/ @param len (Long) length of contents (or {@literal 0N} if unknown)
/ @return (String List) list of header lines
impl.buildHeader:{[token;path;params;len]
    enlist[" "sv(REQ_TYPE;impl.buildQueryStr[path;params];"HTTP/1.1")],
    ": "sv/:flip(key;value)@\:
        (enlist["Host"]!enlist last"/"vs URL),
        REQ_HEADERS,
        (enlist["X-Token"]!enlist token),
        $[null len;()!();enlist["Content-Length"]!enlist string len]
    };

/ Build a query string with path
impl.buildQueryStr:{[path;params]
    path,$[0<count p;1#"?";""],p:"&"sv"="sv/:string flip(key;value)@\:params
    };
    
/ Actually issue a REST query
impl.query:{[headerBuilder;data]
    hsym[`$URL]"\r\n"sv headerBuilder[count d],("";0N!d:.j.j data)
    };

\
__EOD__