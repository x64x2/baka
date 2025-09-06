#define __USE_GNU

#include <fuselagefs/fuselagefs.hh>
#include <errno.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <dirent.h>
#include <fcntl.h>
#include <sys/time.h>
#include <sys/types.h>
#include <attr/xattr.h>
#include <vector>
#include <string>
#include <list>
#include <iterator>
#include <set>

using namespace Fuselage;
using namespace Fuselage::Helpers;

using namespace std;

const string PROGRAM_NAME = "cafe";
const string CACHE_DIRECTORY = "cache-directory";
const string CACHE_INIT_EXE = "cache-init-exe";

void usage(poptContext optCon, int exitcode, char *error, char *addl)
{
    poptPrintUsage(optCon, stderr, 0);
    if (error) fprintf(stderr, "%s: %s0", error, addl);
    exit(exitcode);
}
int exit_status = 0;

const char*  CMDLINE_OPTION_CachePath_CSTR = 0;
const char*  CMDLINE_OPTION_CacheExe_CSTR = 0;
const char*  CMDLINE_OPTION_Options_CSTR = 0;

// thise is same as BASEDIR in fuselage. But here it's required
const char*  CMDLINE_OPTION_BasePath_CSTR = 0;

const char*  RESOLVED_CACHE_DIR = 0;
const char*  RESOLVED_BASE_DIR = 0;

class Cafe
    :
    public Delegatefs
{
    typedef Delegatefs _Base;

public:

  Cafe()
  {
  }
  
  ~Cafe()
  {
  }

  const char*
  toCachePath( const char *path )
  {
    static vector< string > cache;
    int cache_idx = 0;
    int cache_idx_max = 10;
    
    if( cache.empty() )
      {
	for( int i=0; i<cache_idx_max; ++i )
	  cache.push_back( "" );
      }
    
    ++cache_idx;
    cache_idx %= cache_idx_max;
	
    static string ret;
    cache[ cache_idx ] = "";
    stringstream ss;
    ss << RESOLVED_CACHE_DIR << "/" << path;
    
    cache[ cache_idx ] = ss.str();
    return cache[ cache_idx ].c_str();
    }

  virtual int fs_getattr( const char *path, struct stat *sbuf )
  {
    LOG << endl;
    LOG << " path:" << path << endl;
    LOG << " toCachePath:" << toCachePath(path) << endl;
    LOG << endl;
    int rc = lstat( toCachePath(path), sbuf );
    if (rc == -1) {        
      return _Base::fs_getattr( path, sbuf );
    }
    return 0;
  }
  
    virtual int fs_open( const char *path, struct fuse_file_info *fi )
        {
	        LOG << endl;
	
	        int flags = fi->flags;
	        
	        // if not read only then delegate
	        if((flags & 3) != O_RDONLY ) {
	        	return _Base::fs_open( path, fi );
	        }
	
	        LOG << "toCachePath:" << toCachePath( path ) << " flags:" << flags << endl;
	        int fd = open( toCachePath( path ), flags );
	        LOG << "fd:" << fd << endl;
	
	        if (fd == -1)
	        	return _Base::fs_open( path, fi );
	
	        fi->fh = fd;

	        return 0;
        }

};

vector<string> split(const string &sep,string text)
{
  vector<string> words;
  string::size_type end;
    do
      {
        end = text.find(sep);
        if (end == string::npos)
	  end = text.length() + 1;
        words.push_back(text.substr(0,end));
        text.replace(0,end+sep.length(),"");

      } while (text.length());
    return words;
} 

 
int main(int argc, char *argv[])
{
    unsigned long ShowHelp          = 0;

    Cafe myfuse;

    stringstream po;
    po << CACHE_DIRECTORY << "=DIR," << CACHE_INIT_EXE << "=EXE" << endl;

    string possibleOptions = po.str();
    struct poptOption* fuselage_optionsTable = myfuse.getPopTable();
    struct poptOption optionsTable[] =
        {              

	    { NULL, 'o',
	      POPT_ARG_STRING, &CMDLINE_OPTION_Options_CSTR, 0,
	      possibleOptions.c_str(), "OPTIONS" },

	    { CACHE_DIRECTORY.c_str(), 'c',
	      POPT_ARG_STRING, &CMDLINE_OPTION_CachePath_CSTR, 0,
	      "directory to store cached files", "" },

 	    { CACHE_INIT_EXE.c_str(), 'e',
	      POPT_ARG_STRING, &CMDLINE_OPTION_CacheExe_CSTR, 0,
	      "executable to initialize cache", "" },

            { 0, 0, POPT_ARG_INCLUDE_TABLE, fuselage_optionsTable,
              0, "Fuselage options:", 0 },
            
            POPT_AUTOHELP
            POPT_TABLEEND
        };
    
    struct poptOption optionsTableOverride[] =
        {

              { "url", 'u',
  	        POPT_ARG_STRING | POPT_ARGFLAG_DOC_HIDDEN, 
		&CMDLINE_OPTION_BasePath_CSTR, 0,
  	        "directory to use as the backing URL", "" },	          
            
            POPT_AUTOHELP
            POPT_TABLEEND
        };
    
    /// Now do options processing ///
    char c=-1;
    poptContext optConOverride = poptGetContext(PROGRAM_NAME.c_str(), argc, (const char**)argv, optionsTableOverride, 0);
    while ((c = poptGetNextOpt(optConOverride)) != -1)
    {
    }
    poptFreeContext(optConOverride);


    poptContext optCon = poptGetContext(PROGRAM_NAME.c_str(), argc, (const char**)argv, optionsTable, 0);
    poptSetOtherOptionHelp(optCon, "[OPTIONS]* mountpoint");


    while ((c = poptGetNextOpt(optCon)) >= 0)
    {
    }

    if (c < -1) {
      /// an error occurred during option processing ///
      fprintf(stderr, "%s: %s\n", 
              poptBadOption(optCon, POPT_BADOPTION_NOALIAS),
              poptStrerror(c));
      return 1;
    }

    string baseDir = "";
    string mountPoint = "";
    string tempDir = "";

    int argProcessed = 0;

    while( const char* tCSTR = poptGetArg(optCon) )
    {
      argProcessed++;
      string t = tCSTR;

      if (argProcessed == 1) {
	tempDir = t;
      } else {
	if (mountPoint.empty()) {
	  mountPoint = t;
	  cerr << "m:" << mountPoint << endl;
	}
	baseDir = tempDir;
	cerr << "b:" << baseDir << endl;
      }
    }
    if( mountPoint.empty() ) {
      mountPoint = tempDir;
    }
    cerr << "m:" << mountPoint << endl;

    if( mountPoint.empty() )
    {
        cerr << "Error: No mountpoint provided" << endl;
        poptPrintHelp(optCon, stderr, 0);
        exit(1);
    }

    #undef LOG
    #define LOG myfuse.getLogStream() << __PRETTY_FUNCTION__ << " --- " 

    string cachePath;
    string cacheInitExecutable;
    string options;

    //required. Can be also specified by addition argument before mount point
    if (baseDir.empty()) {
      if (CMDLINE_OPTION_BasePath_CSTR != 0) {
	baseDir = CMDLINE_OPTION_BasePath_CSTR;
      } else {
        cerr << "Error: No -u option provided" << endl;
        poptPrintHelp(optCon, stderr, 0);
        exit(1);
      }
    }
    
    // not required
    if (CMDLINE_OPTION_Options_CSTR != 0) {
      options = CMDLINE_OPTION_Options_CSTR;
      vector<string> str_Vector = split(",",options);

      vector<string>::iterator itVectorData;
      for (itVectorData = str_Vector.begin(); itVectorData != str_Vector.end(); 
         itVectorData++)
	{
	  string optionValue = *(itVectorData);
	  vector<string> optionValueVector = split("=",optionValue);
	  if (optionValueVector[0].compare(CACHE_DIRECTORY) == 0) {
	    cachePath = optionValueVector[1];
	  }
	  if (optionValueVector[0].compare(CACHE_INIT_EXE) == 0) {
	    cacheInitExecutable = optionValueVector[1];
	  }
	  cerr << "option:"  << optionValueVector[0] << "=" << optionValueVector[1] << endl;
	}

    }

    // required/can be filled in with option processing
    if (cachePath.empty()) {
      if (CMDLINE_OPTION_CachePath_CSTR != 0) {
	cachePath = CMDLINE_OPTION_CachePath_CSTR;
      } else {
        cerr << "Error: No cache-directory option provided" << endl;
        poptPrintHelp(optCon, stderr, 0);
        exit(1);
      }
    }
    
    // required/can be filled in with option processing
    if (cacheInitExecutable.empty()) {
      if (CMDLINE_OPTION_CacheExe_CSTR != 0) {
	cacheInitExecutable = CMDLINE_OPTION_CacheExe_CSTR;
      } else {
        cerr << "Error: No cache-init-exe option provided" << endl;
        poptPrintHelp(optCon, stderr, 0);
        exit(1);
      }
    }
    
    list<string> fuseArgs;
    fuseArgs.push_back( "cachefs" );

    myfuse.AugmentFUSEArgs( fuseArgs );
    
    // disable multi-threaded operation
    fuseArgs.push_back( "-s" );
    
    // allow mounts over non-empty file/dir
    fuseArgs.push_back( "-o" );
    fuseArgs.push_back( "nonempty" );

    // set filesystem name
    fuseArgs.push_back( "-o" );
    fuseArgs.push_back( "fsname=cachefs" );

   fuseArgs.push_back( "-o" );
//     fuseArgs.push_back( "large_read" );

    fuseArgs.push_back( mountPoint );

    if (CMDLINE_OPTION_BasePath_CSTR == 0) {
      fuseArgs.push_back( baseDir );
    }
    
    LOG << "mountPoint:" << mountPoint << endl;
    LOG << "cacheInitExecutable:" << cacheInitExecutable << endl;
    LOG << "Loading pre-cached directories1 from baseDir:" << baseDir 
	<< " into cachePath:" << cachePath << endl;
    RESOLVED_CACHE_DIR = cachePath.c_str();
    RESOLVED_BASE_DIR = baseDir.c_str();
    system( (cacheInitExecutable+ " " + baseDir + " " + cachePath + ";").c_str() );
    poptFreeContext(optCon);    
    return myfuse.main( fuseArgs );
    
}
