import React from 'react';

function App() {
  const [currentPage, setCurrentPage] = React.useState('home');
  const [initialized, setInitialized] = React.useState(false);

  // List of allowed pages
  const allowedPages = ['home', 'about', 'contact'];

  // Map file paths to page names
  const getPageFromPath = (path: string) => {
    // Extract the page name from the path
    const fileName = path.split('/').pop()?.replace('.tsx', '').toLowerCase();
    // Only return the page name if it's in our allowed list
    return allowedPages.includes(fileName || '') ? fileName : 'home';
  };

  // Update current page when file changes
  React.useEffect(() => {
    const updatePageFromURL = () => {
      if (window.location.search) {
        const params = new URLSearchParams(window.location.search);
        const file = params.get('file');
        if (file) {
          const pageName = getPageFromPath(file);
          console.log('Setting page to:', pageName);
          setCurrentPage(pageName);
        }
      }
    };

    // Initial update
    updatePageFromURL();
    setInitialized(true);

    // Listen for URL changes
    const handlePopState = () => {
      updatePageFromURL();
    };

    window.addEventListener('popstate', handlePopState);
    return () => window.removeEventListener('popstate', handlePopState);
  }, []);

  // Listen for messages from parent window
  React.useEffect(() => {
    const handleMessage = (event: MessageEvent) => {
      if (event.data && event.data.type === 'FILE_CHANGE') {
        const pageName = getPageFromPath(event.data.file);
        console.log('Received file change:', event.data.file, 'Setting page to:', pageName);
        setCurrentPage(pageName);
      }
    };

    window.addEventListener('message', handleMessage);
    return () => window.removeEventListener('message', handleMessage);
  }, []);

  // Handle navigation button clicks
  const handleNavigation = (page: string) => {
    if (!allowedPages.includes(page)) {
      console.error('Invalid page:', page);
      return;
    }
    console.log('Navigation clicked:', page);
    setCurrentPage(page);
    
    // Send message to parent window to handle navigation
    window.parent.postMessage({
      type: 'NAVIGATE',
      page: page
    }, '*');
  };

  function Home() {
    return (
      <div className="max-w-2xl mx-auto">
        <h1 className="text-4xl font-bold mb-4">Welcome Home</h1>
        <p className="text-gray-600 mb-6">
          This is your starting point for building amazing React applications.
        </p>
      </div>
    );
  }

  function About() {
    return (
      <div className="max-w-2xl mx-auto">
        <h1 className="text-4xl font-bold mb-4">About Us</h1>
        <p className="text-gray-600 mb-4">
          Welcome to our React application.
        </p>
      </div>
    );
  }

  function Contact() {
    return (
      <div className="max-w-2xl mx-auto">
        <h1 className="text-4xl font-bold mb-4">Contact Us</h1>
        <p className="text-gray-600 mb-6">
          Have questions? We'd love to hear from you.
        </p>
      </div>
    );
  }

  // Render the current page
  const renderPage = () => {
    if (!initialized) return null;
    console.log('Rendering page:', currentPage);
    switch (currentPage) {
      case 'home':
        return <Home />;
      case 'about':
        return <About />;
      case 'contact':
        return <Contact />;
      default:
        return <Home />;
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
      <nav className="bg-white shadow-md">
        <div className="container mx-auto px-4 py-4">
          <div className="flex justify-between items-center">
            <button
              onClick={() => handleNavigation('home')}
              className="text-2xl font-bold text-blue-600"
            >
              React App
            </button>
            <div className="space-x-4">
              <button
                onClick={() => handleNavigation('home')}
                className={`text-gray-600 hover:text-blue-600 ${currentPage === 'home' ? 'text-blue-600' : ''}`}
              >
                Home
              </button>
              <button
                onClick={() => handleNavigation('about')}
                className={`text-gray-600 hover:text-blue-600 ${currentPage === 'about' ? 'text-blue-600' : ''}`}
              >
                About
              </button>
              <button
                onClick={() => handleNavigation('contact')}
                className={`text-gray-600 hover:text-blue-600 ${currentPage === 'contact' ? 'text-blue-600' : ''}`}
              >
                Contact
              </button>
            </div>
          </div>
        </div>
      </nav>
      
      <main className="container mx-auto px-4 py-8">
        {renderPage()}
      </main>
    </div>
  );
}

export default App;