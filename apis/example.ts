// Example API functions
export const fetchData = async () => {
  // Simulated API call
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve({ data: 'Example data' });
    }, 1000);
  });
};

export const postData = async (data: any) => {
  // Simulated API call
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve({ success: true, data });
    }, 1000);
  });
}; 